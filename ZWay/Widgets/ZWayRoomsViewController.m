//
//  ZWayRoomsViewController.m
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/22/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import "ZWayRoomsViewController.h"
#import "ZWDevice.h"
#import "ZWDeviceItem.h"
#import "ZWayAppDelegate.h"


@interface ZWayRoomsViewController ()

@end

@implementation ZWayRoomsViewController

@synthesize roomDevices;
@synthesize tagsDevices;
@synthesize typesDevices;
@synthesize selected;
@synthesize deviceIndex;
@synthesize displayDevices;
@synthesize tableview;
@synthesize noItemsLabel;
@synthesize authent, changedIP;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
    {
        self.edgesForExtendedLayout = UIRectEdgeAll;
    }
    
    //set up outdoor handler
    authent = [ZWayAuthentification new];
    
    self.tableview.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    //set up 2 second touch to add a device to the dashboard
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                               initWithTarget:self
                                               action:@selector(onLongPress:)];
    longPress.minimumPressDuration = 2.0;
    [self.tableview addGestureRecognizer:longPress];
    
    //set up the double tap recognizer for device updates
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    [self.tableview addGestureRecognizer:tapGesture];

    NSInteger index = [deviceIndex integerValue];
    //set tab and navigation translucent
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setOpaque:YES];
    [self.tabBarController.tabBar setOpaque:YES];
    [self.tabBarController.tabBar setTranslucent:NO];
    
    //set title for subview
    if([selected isEqualToString:NSLocalizedString(@"Rooms", @"")] && roomDevices.count !=0)
        displayDevices = [[NSMutableArray alloc] initWithArray:[roomDevices objectAtIndex:index]];
    else if ([selected isEqualToString:NSLocalizedString(@"Types", @"")])
        displayDevices = [[NSMutableArray alloc] initWithArray:[typesDevices objectAtIndex:index]];
    else if ([selected isEqualToString:NSLocalizedString(@"Tags", @"")])
        displayDevices = [[NSMutableArray alloc] initWithArray:[tagsDevices objectAtIndex:index]];
    
    tableview.hidden = NO;
    noItemsLabel.hidden = YES;
    [tableview reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //set localized label for empty section (empty locations)
    noItemsLabel.text = NSLocalizedString(@"NoDevices", @"");
    
    //load dash objects
    if(ZWayAppDelegate.sharedDelegate.profile.objects)
        objectsToDash = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:ZWayAppDelegate.sharedDelegate.profile.objects]];
    else
        objectsToDash = [NSMutableArray new];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortrait);
}

//method to add a device to the dashboard
-(void)onLongPress:(UILongPressGestureRecognizer*)pGesture
{
    //wait for the touch to end
    if (pGesture.state == UIGestureRecognizerStateEnded)
    {
        //UITableView* tableView = (UITableView*)self.view;
        CGPoint touchPoint = [pGesture locationInView:self.view];
        CGPoint offset = tableview.contentOffset;
        touchPoint.y += offset.y;
        NSIndexPath* indexPath = [tableview indexPathForRowAtPoint:touchPoint];
        
        if (indexPath != nil)
        {
            ZWDevice *device = [displayDevices objectAtIndex:indexPath.row];
            //check if it´s already part of the dashboard
            BOOL moved = [self moveToDash:device];
            
            //inform the user that the device was added
            if(moved == YES)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"MovedTo", @"") message:NSLocalizedString(@"ToDash", @"Message that the device was moved to the D.B.") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
                [alert show];
            }
            //inform the user that the device was not added
            else
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"AlreadyPart", @"") message:NSLocalizedString(@"IsPart", @"Message that the device is already part of the D.B.") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
                [alert show];
            }

        }
    }
}

//method to move devices to the dashboard
- (BOOL)moveToDash:(ZWDevice*)device
{
    BOOL isPart = NO;
    for(NSInteger i=0; i<objectsToDash.count; i++)
    {
        //check if the object is already part of the dashboard
        ZWDevice *dashObject = [objectsToDash objectAtIndex:i];
        if([dashObject.deviceId isEqualToString:device.deviceId])
        {
            isPart = YES;
        }
    }
    
    //if not, add it
    if(isPart == NO)
    {
        [objectsToDash addObject:device];
        return YES;
    }
    
    return NO;
}


- (void)handleTapGesture:(UITapGestureRecognizer *)tGesture
{
    if(tGesture.state == UIGestureRecognizerStateRecognized)
    {
        NSURL *url;
        NSMutableURLRequest *request;
        
        CGPoint touchPoint = [tGesture locationInView:self.view];
        NSIndexPath* indexPath = [tableview indexPathForRowAtPoint:touchPoint];
        ZWDevice *device = [displayDevices objectAtIndex:indexPath.row];
        
        ZWDeviceItem *cell = (ZWDeviceItem*)[tableview cellForRowAtIndexPath:indexPath];
        [cell.contentView setBackgroundColor:[UIColor lightGrayColor]];
        
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
        if(!connection)
        {
            connection = nil;
            NSError *error;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectionFail", @"") message:[error localizedDescription] delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil, nil];
            [alert show];
            receivedData = nil;
        }

    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    receivedData = [NSMutableData new];
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

//Inform the user that the update failed
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectionFail", @"") message:NSLocalizedString(@"FailMessage", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil, nil];
    [alert show];

    receivedData = nil;
    connection = nil;
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
        
        //Check JSON for success code and turn them into device objects
        if([[updated objectForKey:@"message"] isEqualToString:@"200 OK"])
        {
            NSMutableArray *deviceObject = [[updatedDev updateObjects:nil withDict:devices] mutableCopy];
            updatedDev = [deviceObject objectAtIndex:0];
            
            //replace old devices with new ones
            for(int i=0; i<displayDevices.count; i++)
            {
                ZWDevice *device = [displayDevices objectAtIndex:i];
                
                if([updatedDev.deviceId isEqualToString:device.deviceId])
                {
                    [displayDevices replaceObjectAtIndex:i withObject:updatedDev];
                    
                    int row = i;
                    NSIndexPath *index = [NSIndexPath indexPathForRow:row inSection:0];
                    ZWDeviceItem *cell = (ZWDeviceItem*)[tableview cellForRowAtIndexPath:index];
                    sleep(1);
                    [cell.contentView setBackgroundColor:nil];
                }
            }
        }
    }
    
    receivedData = nil;
    connection = nil;
}

//redirect for outdoor use
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSMutableURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == YES)
    {
        return [authent handleAuthentication:request withResponse:response];
    }
    else
        return request;
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

//hide tableview if no devices are to be shown
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(displayDevices.count == 0)
    {
        tableview.hidden = YES;
        noItemsLabel.hidden = NO;
    }
    
    return displayDevices.count;
}


//set height for cells
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(displayDevices.count != 0)
    {
        ZWDevice *device = [displayDevices objectAtIndex:indexPath.row];
        return [device height];
    }
    return 60;
}

//set cells for devices
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(displayDevices.count != 0)
    {
        
    //set display name and cell style
    ZWDevice *device = [displayDevices objectAtIndex:indexPath.row];
    ZWDeviceItem *cell = [device createUIforTableView:tableView atPos:indexPath];
    cell.device = device;
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cell setDisplayName];
    [cell updateState];

    return cell;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier"];
    return cell;
}


//set deleting as editing style
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.editing)
        return UITableViewCellEditingStyleDelete;
    else
        return UITableViewCellEditingStyleNone;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    //save data when leaving the view
    NSData *arrayData = [NSKeyedArchiver archivedDataWithRootObject:objectsToDash];
    ZWayAppDelegate.sharedDelegate.profile.objects = arrayData;
    [ZWDataStore.store.managedObjectContext processPendingChanges];
    [ZWDataStore.store saveContext];
}

@end
