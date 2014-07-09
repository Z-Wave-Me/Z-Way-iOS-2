//
//  ZWayNotificationViewController.m
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/21/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import "ZWayNotificationViewController.h"
#import "ZWDataHandler.h"
#import "ZWayWidgetViewController.h"

@interface ZWayNotificationViewController ()

@end

@implementation ZWayNotificationViewController

@synthesize noItemsLabel;
@synthesize tableview;
@synthesize authent;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    cellField = [NSMutableDictionary dictionary];
    [cellField setObject:[[[NSBundle mainBundle] loadNibNamed:@"NotificationCell" owner:self options:nil] objectAtIndex:0] forKey:@"notCell"];
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
    {
        self.edgesForExtendedLayout = UIRectEdgeAll;
    }
    
    //set up outdoor handler
    authent = [ZWayAuthentification new];

    //load from scratch
    [self getNotifications:[NSNumber numberWithLong:0]];
    
    //set editing button and the navigation bar translucent
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setOpaque:YES];
    [self.tabBarController.tabBar setTranslucent:NO];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationItem.rightBarButtonItem.style = UIBarButtonItemStylePlain;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //set localized title and label
    [self setTitle:NSLocalizedString(@"Notifications", @"")];
    self.noItemsLabel.text = NSLocalizedString(@"OKMessage", @"");
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    if(notifications.count != 0)
    {
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
        self.navigationItem.rightBarButtonItem.style = UIBarButtonItemStylePlain;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortrait);
}

//attach bars at top
- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

//Method to load notifications
- (void)getNotifications:(NSNumber*)timestamp
{
    NSURL *url;
    NSMutableURLRequest *request;
    currentTimestamp = timestamp;
    
    //check if outdoor and find.z-wave.me should be used
    if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == YES)
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://find.z-wave.me/ZAutomation/api/v1/notifications?since=%@", timestamp]];
    //use local IP
    else
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/ZAutomation/api/v1/notifications?since=%@", ZWayAppDelegate.sharedDelegate.profile.indoorUrl, timestamp]];
    
    request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:30.0];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [request setValue:@"gzip, deflate, sdch" forHTTPHeaderField:@"Accept-Encoding"];

    //create connection and check if it was successful
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if(!connection && alertShown == false)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error!", @"") message:NSLocalizedString(@"UpdateError", @"Message that a problem occured during the update") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [alert show];
        alertShown = true;
    }
}

//method to check the response
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    notificationData = [NSMutableData new];
    [notificationData setLength:0];
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger responseStatusCode = [httpResponse statusCode];
    
    //alert the user if an error occured
    if(responseStatusCode != 200 && alertShown == false)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectionFail", @"") message:NSLocalizedString(@"FailMessage", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil, nil];
        [alert show];
        alertShown = true;
    }
    else
        alertShown = false;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [notificationData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    connection = nil;
    notificationData = nil;
    //load data from scratch when an error occured
    [self performSelector:@selector(getNotifications:) withObject:[NSNumber numberWithInt:0] afterDelay:20.0];
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError *error;
    //extract parsed notifications
    NSDictionary *notificationJSON = [NSJSONSerialization JSONObjectWithData:notificationData options:NSJSONReadingMutableContainers error:&error];
    NSDictionary *notificationDict = [notificationJSON objectForKey:@"data"];
    int timestamp;
    
    if(![notificationDict objectForKey:@"id"])
    {
        if(notificationDict != (id)[NSNull null])
        {
            NSMutableArray *sort = [notificationDict objectForKey:@"notifications"];
            //timestamp = [[notificationDict valueForKey:@"updateTime"] integerValue];
            timestamp = 0;
        
            //filter all redeemed notifications
            for(int i=0; i<sort.count; i++)
            {
                BOOL redeemed = [[[sort objectAtIndex:i] objectForKey:@"redeemed"] boolValue];
            
                if(redeemed == YES)
                {
                    [sort removeObjectAtIndex:i];
                }
            }
        
            //set only notifications that should be shown
            notifications = sort;
        }
        else
            timestamp = 0;
    }
    else
        timestamp = 0;
    
    NSLog(@"notifications: %@", notificationJSON);
    
    //disable edit button if no notification is found
    if(notifications.count == 0)
        self.navigationItem.rightBarButtonItem.enabled = NO;
    
    connection = nil;
    notificationData = nil;
    alertShown = false;
    
    [tableview reloadData];
    
    //load notifications after 30 with last timestamp
    [self performSelector:@selector(getNotifications:) withObject:[NSNumber numberWithLong:timestamp] afterDelay:30.0];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return YES;
}

//redirect method for outdoor use
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSMutableURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == YES)
        return [authent handleAuthentication:request withResponse:response];
    else
        return request;
}

//tableview only has one section
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

//number of rows equals notifications
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //hide tableview when no notifications
    if(notifications.count == 0)
    {
        tableView.hidden = YES;
        noItemsLabel.hidden = NO;
    }
    else
    {
        tableView.hidden = NO;
        noItemsLabel.hidden = YES;
    }
    return notifications.count;
}

//same height for all notifiations
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"notification";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"NotificationCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    //display message
    NSDictionary *message = [notifications objectAtIndex:indexPath.row];
    
    UILabel *timeStampLabel = (UILabel*)[cell viewWithTag:1];
    NSString *timestamp =[NSString stringWithFormat:@"%@", [message valueForKey:@"timestamp"]];
    timeStampLabel.text = [timestamp substringToIndex:MIN(10, [timestamp length])];
    
    UILabel *messageLabel = (UILabel*)[cell viewWithTag:2];
    messageLabel.text = [NSString stringWithFormat:@"%@", [message valueForKey:@"message"]];

    return cell;
}

//enable editing of rows
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

//editing style is deleting
-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.editing)
        return UITableViewCellEditingStyleDelete;
    else
        return UITableViewCellEditingStyleNone;
}

//set tableview in editing mode
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.tableview setEditing:editing animated:animated];
}

//method to delete notifications, has to be implemented yet in API
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSDictionary *noti = [notifications objectAtIndex:indexPath.row];
        NSString *notID = [noti valueForKey:@"id"];
        NSNumber *formID = [NSNumber numberWithLongLong:[notID longLongValue]];
        
        NSURL *url;
        NSMutableURLRequest *request;
        
        NSString *body = [NSString stringWithFormat:@"{\"id\":%@,\"timestamp\":\"%@\",\"level\":\"%@\",\"message\":\"%@\",\"redeemed\":true}", formID, [noti valueForKey:@"timestamp"], [noti valueForKey:@"level"], [noti valueForKey:@"message"]];
        
        if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == YES)
            url = [NSURL URLWithString:[NSString stringWithFormat:@"https://find.z-wave.me/ZAutomation/api/v1/notifications/%@", formID]];
        else
            url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/ZAutomation/api/v1/notifications/%@", ZWayAppDelegate.sharedDelegate.profile.indoorUrl, formID]];
        
        request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:20.0];
        [request setHTTPMethod:@"PUT"];
        [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
        [request setValue:@"gzip, deflate, sdch" forHTTPHeaderField:@"Accept-Encoding"];
        [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        
        if(!connection && alertShown == false)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error!", @"") message:NSLocalizedString(@"UpdateError", @"Message that a problem occured during the update") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
            [alert show];
            alertShown = true;
        }
        
        //check if it´s the last notification
        if(notifications.count -1 != 0)
        {
            [notifications removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        //if yes hide the tableview
        else
        {
            tableview.hidden = YES;
            noItemsLabel.hidden = NO;
            self.navigationItem.rightBarButtonItem.enabled = NO;
            [notifications removeObjectAtIndex:indexPath.row];
        }
    }
}

@end
