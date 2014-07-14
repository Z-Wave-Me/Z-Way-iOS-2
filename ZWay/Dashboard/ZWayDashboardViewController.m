//
//  ZWayFirstViewController.m
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/15/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import "ZWayDashboardViewController.h"
#import "ZWDevice.h"
#import "ZWDeviceItem.h"
#import "ZWDataHandler.h"
#import "ZWayAppDelegate.h"
#import "NSData+Base64.h"


@class ZWDevice;

@interface ZWayDashboardViewController ()

@end

@implementation ZWayDashboardViewController
@synthesize noItemsLabel;
@synthesize tableview;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
    {
        self.edgesForExtendedLayout = UIRectEdgeAll;
    }
    
    //Tabbar items localization since it´s the first view controller
    [[self.tabBarController.tabBar.items objectAtIndex:0] setTitle:NSLocalizedString(@"Dashboard", @"")];
    [[self.tabBarController.tabBar.items objectAtIndex:1] setTitle:NSLocalizedString(@"Widgets", @"")];
    [[self.tabBarController.tabBar.items objectAtIndex:2] setTitle:NSLocalizedString(@"Notifications", @"")];
    [[self.tabBarController.tabBar.items objectAtIndex:3] setTitle:NSLocalizedString(@"Options", @"")];
    
    //remove title
    self.title = nil;
    
    ////set green dot to show connection
    UIImage* image = [UIImage imageNamed:@"connection.png"];
    CGRect frameimg = CGRectMake(0, 0, image.size.width, image.size.height);
    UIButton *someButton = [[UIButton alloc] initWithFrame:frameimg];
    [someButton setBackgroundImage:image forState:UIControlStateNormal];
    [someButton setHighlighted:NO];
    someButton.enabled = NO;
    
    UIBarButtonItem *connected =[[UIBarButtonItem alloc] initWithCustomView:someButton];
    self.navigationItem.leftBarButtonItem = connected;
    
    //set tab and navigation translucent so they don´t overlap the tableview
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setOpaque:YES];
    [self.tabBarController.tabBar setTranslucent:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //update all objects as soon as the view loads
    [self updateObjects];
    
    //check if a profile is selected and hide tableview when not
    if (ZWayAppDelegate.sharedDelegate.profile != nil)
    {
        //get Objects for profile
        if(ZWayAppDelegate.sharedDelegate.profile.objects)
            objects = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:ZWayAppDelegate.sharedDelegate.profile.objects]];
    
        //hide tableview when no objects were found
        if(objects.count != 0)
        {
            tableview.hidden = NO;
            noItemsLabel.hidden = YES;
            self.navigationItem.rightBarButtonItem = self.editButtonItem;
            self.navigationItem.rightBarButtonItem.style = UIBarButtonItemStylePlain;
            self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Edit", @"");
        }
        else
        {
            tableview.hidden = YES;
            noItemsLabel.hidden = NO;
            self.navigationItem.rightBarButtonItem = nil;
        }
        [tableview reloadData];
    }
    else
    {
        tableview.hidden = YES;
        noItemsLabel.hidden = NO;
    }
    
    [self setEditing:NO animated:NO];
    
    //set localized text for empty dashboard
    noItemsLabel.text = NSLocalizedString(@"NoDashboard", @"");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortrait);
}

//top attached bars
- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}


//method to update the objects
- (void)updateObjects
{
    //reload before next update
    [tableview reloadData];
    
    //load objetcs from profile
    if(ZWayAppDelegate.sharedDelegate.profile.objects)
        objects = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:ZWayAppDelegate.sharedDelegate.profile.objects]];
    
    [tableview reloadData];
    
    //update all objects
    for (int i=0; i<objects.count; i++)
    {
        ZWDevice *device = [objects objectAtIndex:i];
        currentdevice = device;
        notFound = device;
        receivedData = nil;
        NSURL *url;
        NSMutableURLRequest *request;
        
        //in case it´s outdoor use find.z-wave.me
        if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == YES)
            url = [NSURL URLWithString:[NSString stringWithFormat:@"https://find.z-wave.me/ZAutomation/api/v1/devices/%@", device.deviceId]];
        //else use local IP
        else
            url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/ZAutomation/api/v1/devices/%@", ZWayAppDelegate.sharedDelegate.profile.indoorUrl,device.deviceId]];
        
        request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:10.0];
        [request setHTTPMethod:@"GET"];
        [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
        [request setValue:@"gzip, deflate, sdch" forHTTPHeaderField:@"Accept-Encoding"];
        
        //create connection and check if it was successful
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        if(!connection && alertShown == false)
        {
            connection = nil;
            NSError *error;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectionFail", @"") message:[error localizedDescription] delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil, nil];
            [alert show];
            alertShown = true;
            receivedData = nil;
        }
    }
}

//Method to check the response
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    receivedData = [NSMutableData new];
    [receivedData setLength:0];
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger responseStatusCode = [httpResponse statusCode];
    
    //check response code
    if(responseStatusCode != 200)
    {
        //check if object was not found
        if(responseStatusCode == 404)
        {
            //remove the object from the dashboard
            [objects removeObject:notFound];
            ZWayAppDelegate.sharedDelegate.profile.objects = [NSKeyedArchiver archivedDataWithRootObject:objects];
            connection = nil;
            receivedData = nil;
        }
    }
    else
        alertShown = false;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

//Method to alert the user that an error occured
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if(alertShown == false)
    {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectionFail", @"") message:NSLocalizedString(@"FailMessage", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil, nil];
    [alert show];
        alertShown = true;
    }
    receivedData = nil;
    connection = nil;
    
    //set green dot to show connection
    UIImage* image = [UIImage imageNamed:@"noConnection.png"];
    CGRect frameimg = CGRectMake(0, 0, image.size.width, image.size.height);
    UIButton *someButton = [[UIButton alloc] initWithFrame:frameimg];
    [someButton setBackgroundImage:image forState:UIControlStateNormal];
    [someButton setHighlighted:NO];
    someButton.enabled = NO;
    
    UIBarButtonItem *connected =[[UIBarButtonItem alloc] initWithCustomView:someButton];
    self.navigationItem.leftBarButtonItem = connected;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSDictionary *updated = [NSDictionary new];
    NSError *error;
    if(receivedData)
    {
        //serialize and extract data from parsed JSON
        updated = [NSJSONSerialization JSONObjectWithData:receivedData options:NSJSONReadingMutableContainers error:&error];
        NSMutableDictionary *devices = [updated objectForKey:@"data"];
        
        ZWDevice *updatedDev = [ZWDevice new];
        NSMutableArray *updatedArray = [NSMutableArray new];
        
        //Check JSON for success code and turn them into device objects
        if([[updated objectForKey:@"message"] isEqualToString:@"200 OK"])
        {
        updatedArray = [[updatedDev updateObjects:nil withDict:devices] mutableCopy];
        updatedDev = [updatedArray objectAtIndex:0];
        
        //replace old devices with new ones
        for(int i=0; i<objects.count; i++)
        {
            ZWDevice *device = [objects objectAtIndex:i];
                
            if([updatedDev.deviceId isEqualToString:device.deviceId])
                [objects replaceObjectAtIndex:i withObject:updatedDev];
        }
        }
    }
    
    //set green dot to show connection
    UIImage* image = [UIImage imageNamed:@"connection.png"];
    CGRect frameimg = CGRectMake(0, 0, image.size.width, image.size.height);
    UIButton *someButton = [[UIButton alloc] initWithFrame:frameimg];
    [someButton setBackgroundImage:image forState:UIControlStateNormal];
    [someButton setHighlighted:NO];
    someButton.enabled = NO;
    
    UIBarButtonItem *connected =[[UIBarButtonItem alloc] initWithCustomView:someButton];
    self.navigationItem.leftBarButtonItem = connected;
    
    receivedData = nil;
    connection = nil;
    alertShown = false;
}

-(BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return YES;
}

//redirect for outdoor use
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSMutableURLRequest *)request redirectResponse:(NSURLResponse *)response
{    
    if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == YES)
    {
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger responseStatusCode = [httpResponse statusCode];
    
    NSURL *url;
    
    //run normal request after authentication
    if(responseStatusCode >= 300 && responseStatusCode <= 400)
    {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://find.z-wave.me/ZAutomation/api/v1/devices/%@", currentdevice.deviceId]];
        request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:30.0];
        
        [request setHTTPMethod:@"GET"];
        [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
        [request setValue:@"gzip, deflate, sdch" forHTTPHeaderField:@"Accept-Encoding"];
        return request;
    }
    //provide credentials
    else
    {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://find.z-wave.me/zboxweb"]];
        request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:30.0];
        
        NSString *postString = [NSString stringWithFormat:@"act=login&login=%@&pass=%@", ZWayAppDelegate.sharedDelegate.profile.userLogin, ZWayAppDelegate.sharedDelegate.profile.userPassword];
        NSData *myRequestData = [postString dataUsingEncoding: NSUTF8StringEncoding];
        
        [request setHTTPMethod:@"POST"];
        [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
        [request setValue:@"gzip, deflate, sdch" forHTTPHeaderField:@"Accept-Encoding"];
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[myRequestData length]] forHTTPHeaderField:@"Content-length"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
        [request setHTTPBody:myRequestData];
        return request;
    }
    }
    else
        return request;
}

#pragma mark: Cell definition

//enable editing of rows
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

//Set rows in tabeview to count of objects
- (NSInteger)tableView:tableView numberOfRowsInSection:(NSInteger)section
{
    return objects.count;
}


//set height for cells
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(objects.count != 0)
    {
        ZWDevice *device = [objects objectAtIndex:indexPath.row];
        return [device height];
    }
    return 60;
}


//display the devives
- (ZWDeviceItem *)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //set title and type of cell
    if(objects.count != 0)
    {
        ZWDevice *device = [objects objectAtIndex:indexPath.row];
        ZWDeviceItem *cell = [device createUIforTableView:tableView atPos:indexPath];
        cell.device = device;
        [cell setDisplayName];
        [cell updateState];
        
        cell.showsReorderControl = YES;
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        //hide controls if in edit mode
        [cell hideControls:editMode];
        return cell;
    }
    //hide tableview when no items on dashboard
    else
    {
        noItemsLabel.hidden = NO;
        tableview.hidden = YES;
        ZWDeviceItem *cell = [[ZWDeviceItem alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        return cell;
    }
}

//set deletion mode when editing
-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.editing)
        return UITableViewCellEditingStyleDelete;
    else
        return UITableViewCellEditingStyleNone;
}

//set the tableview in editing mode and hide controls
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.tableview setEditing:editing animated:animated];
    editMode = editing;
    [self.tableview performSelector:@selector(reloadData) withObject:nil afterDelay:0.3];
}


// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}


// Rearanging the cells
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    ZWDevice *deviceA = [objects objectAtIndex:fromIndexPath.row];
    [objects removeObjectAtIndex:fromIndexPath.row];
    [objects insertObject:deviceA atIndex:toIndexPath.row];
    NSData *objectData = [NSKeyedArchiver archivedDataWithRootObject:objects];
    ZWayAppDelegate.sharedDelegate.profile.objects = objectData;
}


//Method to delete the devices from the dashboard
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //check if it´s the last item on the dashboard
        if(objects.count -1 != 0)
        {
            [objects removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        //if yes then hide the tableview afterwards
        else
        {
            tableview.hidden = YES;
            noItemsLabel.hidden = NO;
            self.navigationItem.rightBarButtonItem = nil;
            [objects removeObjectAtIndex:indexPath.row];
        }
        
        //save the remaining objects
        NSData *objectData = [NSKeyedArchiver archivedDataWithRootObject:objects];
        ZWayAppDelegate.sharedDelegate.profile.objects = objectData;
    }
}

//save objects when view disappears
- (void)viewWillDisappear:(BOOL)animated
{
    NSData *objectData = [NSKeyedArchiver archivedDataWithRootObject:objects];
    ZWayAppDelegate.sharedDelegate.profile.objects = objectData;
}

@end
