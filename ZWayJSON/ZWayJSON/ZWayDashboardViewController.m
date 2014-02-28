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


@class ZWDevice;

@interface ZWayDashboardViewController ()

@end

@implementation ZWayDashboardViewController
@synthesize noItemsLabel;
@synthesize tableview;


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (ZWayAppDelegate.sharedDelegate.profile != nil)
    {
        //get Objects for profile
        objects = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:ZWayAppDelegate.sharedDelegate.profile.objects]];
    
        if(objects.count != 0)
        {
            tableview.hidden = NO;
            noItemsLabel.hidden = YES;
            self.navigationItem.rightBarButtonItem = self.editButtonItem;
            self.navigationItem.rightBarButtonItem.style = UIBarButtonItemStylePlain;
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
    
    noItemsLabel.text = NSLocalizedString(@"NoDashboard", @"");
    [self updateObjects];
}

- (void)updateObjects
{
    objects = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:ZWayAppDelegate.sharedDelegate.profile.objects]];
    [tableview reloadData];
    
    for (int i=0; i<objects.count; i++)
    {
        ZWDevice *device = [objects objectAtIndex:i];
        receivedData = nil;
        NSURL *url;
        
        if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == NO)
            url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/ZAutomation/api/v1/devices/%@", ZWayAppDelegate.sharedDelegate.profile.indoorUrl, device.deviceId]];
        else
            url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/ZAutomation/api/v1/devices/%@", ZWayAppDelegate.sharedDelegate.profile.outdoorUrl, device.deviceId]];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:60.0];
        [request setHTTPMethod:@"GET"];
        
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        if(!connection && alertShown == NO)
        {
            connection = nil;
            NSError *error;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectionFail", @"") message:[error localizedDescription] delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil, nil];
            [alert show];
            alertShown = YES;
            receivedData = nil;
        }
    }
    [self performSelector:@selector(updateObjects) withObject:nil afterDelay:10.0];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    receivedData = [NSMutableData new];
    [receivedData setLength:0];
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
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    receivedData = nil;
    connection = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSDictionary *updated = [NSDictionary new];
    NSError *error;
    if(receivedData)
    {
        updated = [NSJSONSerialization JSONObjectWithData:receivedData options:NSJSONReadingMutableContainers error:&error];
        NSDictionary *devices = [updated objectForKey:@"data"];
        
        ZWDevice *updatedDev = [ZWDevice new];
        NSMutableArray *updatedArray = [NSMutableArray new];
        
        if([[updated objectForKey:@"message"] isEqualToString:@"200 OK"])
        {
        updatedArray = [[updatedDev updateObjects:nil WithDict:devices] mutableCopy];
        updatedDev = [updatedArray objectAtIndex:0];
        
        for(int i=0; i<objects.count; i++)
        {
            ZWDevice *device = [objects objectAtIndex:i];
                
            if([updatedDev.deviceId isEqualToString:device.deviceId])
                [objects replaceObjectAtIndex:i withObject:updatedDev];
        }
        }
    }
    receivedData = nil;
    connection = nil;
    alertShown = NO;
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
    if(objects.count != 0)
    {
        ZWDevice *device = [objects objectAtIndex:indexPath.row];
        ZWDeviceItem *cell = [device createUIforTableView:tableView atPos:indexPath];
        cell.device = device;
        [cell setDisplayName];
        [cell updateState];
        
        ZWDeviceItem __weak *weakCell = cell;
        
        [weakCell setAppearanceWithBlock:^{
            weakCell.containingTableView = tableView;
            [weakCell setCellHeight:weakCell.frame.size.height];
            
            NSMutableArray *rightUtilityButtons = [NSMutableArray new];
            
            [rightUtilityButtons sw_addUtilityButtonWithColor:
             [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                        title:NSLocalizedString(@"Remove", @"Remove Button")];
            weakCell.rightUtilityButtons = rightUtilityButtons;
            weakCell.delegate = self;
        } force:NO];
        
        weakCell.showsReorderControl = YES;
        [cell hideControls:editMode];
        return cell;
    }
    else
    {
        noItemsLabel.hidden = NO;
        tableview.hidden = YES;
        ZWDeviceItem *cell = [[ZWDeviceItem alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        return cell;
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
        {
            NSIndexPath *cellIndexPath = [tableview indexPathForCell:cell];
            if(objects.count -1 != 0)
            {
                [objects removeObjectAtIndex:cellIndexPath.row];
                [tableview deleteRowsAtIndexPaths:[NSArray arrayWithObject:cellIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                NSData *objectData = [NSKeyedArchiver archivedDataWithRootObject:objects];
                ZWayAppDelegate.sharedDelegate.profile.objects = objectData;
            }
            else
            {
                tableview.hidden = YES;
                noItemsLabel.hidden = NO;
                [objects removeObjectAtIndex:cellIndexPath.row];
            }
        }
            break;
            
        default:
            break;
    }
}


-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.editing)
        return UITableViewCellEditingStyleDelete;
    else
        return UITableViewCellEditingStyleNone;
}

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


// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    ZWDevice *deviceA = [objects objectAtIndex:fromIndexPath.row];
    [objects removeObjectAtIndex:fromIndexPath.row];
    [objects insertObject:deviceA atIndex:toIndexPath.row];
    NSData *objectData = [NSKeyedArchiver archivedDataWithRootObject:objects];
    ZWayAppDelegate.sharedDelegate.profile.objects = objectData;
}


//what to do when editing
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if(objects.count -1 != 0)
        {
            [objects removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            NSData *objectData = [NSKeyedArchiver archivedDataWithRootObject:objects];
            ZWayAppDelegate.sharedDelegate.profile.objects = objectData;
        }
        else
        {
            tableview.hidden = YES;
            noItemsLabel.hidden = NO;
            [objects removeObjectAtIndex:indexPath.row];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSData *objectData = [NSKeyedArchiver archivedDataWithRootObject:objects];
    ZWayAppDelegate.sharedDelegate.profile.objects = objectData;
}

@end
