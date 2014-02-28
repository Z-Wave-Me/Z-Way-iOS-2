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

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Notifications", @"Notifications");
    self.noItemsLabel.text = NSLocalizedString(@"OKMessage", @"");
}

- (void)viewDidAppear:(BOOL)animated
{
    ZWDataHandler *handler = [ZWDataHandler new];
    
    NSData *encodedJSON = [[NSUserDefaults standardUserDefaults] objectForKey:@"JSON"];
    if(encodedJSON != nil)
    {
        JSON = [NSKeyedUnarchiver unarchiveObjectWithData:encodedJSON];
        NSInteger timestamp = [handler getTimestamp:JSON];
        [self getNotifications:timestamp];
    }
    else
        [self getNotifications:0];
}

- (void)getNotifications:(NSInteger)timestamp
{
    NSURL *url;
    
    if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == NO)
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/ZAutomation/api/v1/notifications?since=%u",ZWayAppDelegate.sharedDelegate.profile.indoorUrl, timestamp]];
    else
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/ZAutomation/api/v1/notifications?since=%u",ZWayAppDelegate.sharedDelegate.profile.outdoorUrl, timestamp]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:45.0];
    [request setHTTPMethod:@"GET"];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if(!connection && alertShown == NO)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:NSLocalizedString(@"UpdateError", @"Message that a problem occured during the update") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [alert show];
        alertShown = YES;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    notificationData = [NSMutableData new];
    [notificationData setLength:0];
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    int responseStatusCode = [httpResponse statusCode];
    
    if(responseStatusCode != 200 && alertShown == NO)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectionFail", @"") message:NSLocalizedString(@"FailMessage", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil, nil];
        [alert show];
        alertShown = YES;
    }
    else
        alertShown = NO;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [notificationData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    connection = nil;
    notificationData = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError *error;
    NSDictionary *notificationJSON = [NSJSONSerialization JSONObjectWithData:notificationData options:NSJSONReadingMutableContainers error:&error];
    NSDictionary *notificationDict = [notificationJSON objectForKey:@"data"];
    int timestamp;
    
    if(notificationDict != (id)[NSNull null])
    {
        notifications = [notificationDict objectForKey:@"notifications"];
        NSString *updateTime = [notificationDict objectForKey:@"updateTime"];
        timestamp = [updateTime integerValue];
    }
    else
        timestamp = 0;
    
    connection = nil;
    notificationData = nil;
    alertShown = NO;
    
    [self performSelector:@selector(getNotifications:) withObject:[NSNumber numberWithInt:timestamp] afterDelay:30.0];
}

- (BOOL)connection:(NSURLConnection*)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    NSString* method = protectionSpace.authenticationMethod;
    return [method isEqualToString:NSURLAuthenticationMethodServerTrust] || [method isEqualToString:NSURLAuthenticationMethodDefault];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSString *method = challenge.protectionSpace.authenticationMethod;
    NSURLCredential *credentials = [[NSURLCredential alloc] initWithUser:ZWayAppDelegate.sharedDelegate.profile.userLogin password:ZWayAppDelegate.sharedDelegate.profile.userPassword persistence:NSURLCredentialPersistenceNone];
    
    
    if ([method isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    }
    else if ([method isEqualToString:NSURLAuthenticationMethodDefault] && credentials != nil)
    {
        if ([challenge previousFailureCount] > 0)
        {
            [challenge.sender cancelAuthenticationChallenge:challenge];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CredentialError", @"Authentication Error") message:NSLocalizedString(@"WrongCred", @"Can´t connect with these credentials") delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            [challenge.sender useCredential:credentials forAuthenticationChallenge:challenge];
        }
    }
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
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

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSDictionary *message = [notifications objectAtIndex:indexPath.row];
    UIImageView *image = (UIImageView*)[tableView viewWithTag:1];
    image.image = [UIImage imageNamed:@""];
    UILabel *label = (UILabel*)[tableView viewWithTag:2];
    label.text = [NSString stringWithFormat:@"%@", [message objectForKey:@"message"]];
    return cell;
}

@end
