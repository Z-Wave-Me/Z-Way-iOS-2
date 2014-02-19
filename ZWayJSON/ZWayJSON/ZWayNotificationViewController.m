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
        notificationData = [handler getNotifications:timestamp];
    }
    [self extractNotifications:notificationData];
}

- (void)extractNotifications:(NSDictionary *)dictionary
{
    if([[dictionary objectForKey:@"message"] isEqualToString:@"200 OK"])
        notifications = [[dictionary objectForKey:@"notifications"] mutableCopy];
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:NSLocalizedString(@"UpdateError", @"Message that a problem occured during the update") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [alert show];
    }
    
    [self performSelector:@selector(viewDidAppear:) withObject:[NSNumber numberWithBool:YES] afterDelay:30.0];
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
