//
//  ZWaySecondViewController.m
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/15/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import "ZWayWidgetViewController.h"
#import "ZWayDashboardViewController.h"
#import "ZWayAppDelegate.h"
#import "ZWDeviceItem.h"
#import "ZWDevice.h"
#import "ZWDataHandler.h"
#import "ZWayRoomsViewController.h"
#import "ZWayNotificationViewController.h"
#import "NSData+Base64.h"

@interface ZWayWidgetViewController ()

@end

@implementation ZWayWidgetViewController

@synthesize currentButton;
@synthesize tableview;
@synthesize rooms, types, tags;
@synthesize objects;
@synthesize JSON;
@synthesize roomObjects, typeObjects, tagObjects;
@synthesize deviceIndex;
@synthesize tagsButton, typesButton, roomsButton;
@synthesize noItemsLabel;
@synthesize toolbar;
@synthesize authent;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
    {
        self.tableview.contentInset = UIEdgeInsetsMake(0.0f, 0.0f,  CGRectGetHeight(self.toolbar.frame), 0.0f);
        self.edgesForExtendedLayout = UIRectEdgeAll;
    }
    
    //set up toolbar
    toolbar.delegate = self;
    [self.navigationController setToolbarHidden:NO];
    [self.toolbar setTranslucent:NO];
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.tabBarController.tabBar setTranslucent:NO];
    [self setToolbarItems:[NSArray arrayWithObjects: self.typesButton, self.roomsButton, self.tagsButton, nil] animated:NO];
    
    //set up auth handler
    authent = [ZWayAuthentification new];
    
    //load notifications
    handler = [ZWDataHandler new];
    [handler setUpAuth];
    [handler getLocations];
    
    currentButton = NSLocalizedString(@"Types", @"");
    
    //update devices
    if(handler.locationTitles)
        [self updateDevices:[NSNumber numberWithLong:0]];
    else
        [self performSelector:@selector(updateDevices:) withObject:[NSNumber numberWithLong:0] afterDelay:1];
    
    alertShown = false;
    firstUpdate = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:NO animated:NO];
    
    //localize in case the language changed
    [self setTitle:NSLocalizedString(@"Widgets", @"")];
    roomsButton.title = NSLocalizedString(@"Rooms", @"");
    typesButton.title = NSLocalizedString(@"Types", @"");
    tagsButton.title = NSLocalizedString(@"Tags", @"");
    noItemsLabel.text = NSLocalizedString(@"NoDevices", @"");
    
    if([currentButton isEqualToString:NSLocalizedString(@"Rooms", @"")])
        [self roomsSelected:self];
    else if([currentButton isEqualToString:NSLocalizedString(@"Tags", @"")])
        [self tagsSelected:self];
    else
        [self typesSelected:self];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortrait);
}

//top attach bars
- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}

//method to update the devices
- (void)updateDevices:(NSNumber*)timestamp
{
    NSURL *url;
    NSMutableURLRequest *request;
    
    //check if find.z-wave.me should be used
    if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == YES)
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://find.z-wave.me/ZAutomation/api/v1/devices?since=%@", timestamp]];
    //or use local IP if not
    else
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/ZAutomation/api/v1/devices?since=%@", ZWayAppDelegate.sharedDelegate.profile.indoorUrl, timestamp]];
    
    request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:30.0];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [request setValue:@"gzip, deflate, sdch" forHTTPHeaderField:@"Accept-Encoding"];
    
    //create connection and check if it was successful
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if(!connection && alertShown == false)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error!", @"") message:NSLocalizedString(@"UpdateError", @"Message that an error occured during the update") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [alert show];
        alertShown = true;
        receivedObjects = nil;
    }
}

//method to check response
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    receivedObjects = [NSMutableData new];
    [receivedObjects setLength:0];
    
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger responseStatusCode = [httpResponse statusCode];

    if(responseStatusCode == 200)
        alertShown = false;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedObjects appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    connection = nil;
    receivedObjects = nil;
    
    //load device from scratch if connection failed
    [self performSelector:@selector(updateDevices:) withObject:[NSNumber numberWithInt:0] afterDelay:10.0];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    ZWDevice *device = [ZWDevice new];
    NSError *error;
    NSMutableArray *updated = [NSMutableArray new];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    //extract data from parsed JSON
    JSON = [NSJSONSerialization JSONObjectWithData:receivedObjects options:NSJSONReadingMutableContainers error:&error];
        
    updated = [[JSON objectForKey:@"data"] objectForKey:@"devices"];
    NSInteger timestamp = [handler getTimestamp:JSON firstTime:firstUpdate];
    
    //load old objects in case the JSON is empty and alert the user
    if(updated.count == 0 && [[[JSON objectForKey:@"data"] objectForKey:@"structureChanged"] boolValue] == 1)
    {
        NSData *encodedJSON = [defaults objectForKey:@"JSON"];
        NSData *encodedObjects = [defaults objectForKey:@"Devices"];
    
        objects = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObjects];
        JSON = [NSKeyedUnarchiver unarchiveObjectWithData:encodedJSON];
        
        if(alertShown == false)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error!", @"") message:NSLocalizedString(@"UpdateError", @"Message that an error occured during the update") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
            [alert show];
            alertShown = true;
        }
    }
    //or turn the JSON into objects
    else
    {
        if(firstUpdate == YES)
        {
            objects = [device updateObjects:updated withDict:nil];
        }
        else
        {
            NSData *encodedOb = [defaults objectForKey:@"Devices"];
            objects = [NSKeyedUnarchiver unarchiveObjectWithData:encodedOb];
            NSMutableArray *compare = [device updateObjects:updated withDict:nil];
            
            for(int i=0; i<compare.count; i++)
            {
                ZWDevice *device = [compare objectAtIndex:i];
                for(int j=0; j<objects.count; j++)
                {
                    ZWDevice *objectDecive = [objects objectAtIndex:j];
                    if([device.deviceId isEqualToString:objectDecive.deviceId])
                    {
                        [objects replaceObjectAtIndex:j withObject:device];
                    }
                }
            }
        }
    }
    
    NSData *encodedObjects = [NSKeyedArchiver archivedDataWithRootObject:objects];
    [defaults setObject:encodedObjects forKey:@"Devices"];
    
    //if(firstUpdate == NO)
        //NSLog(@"Objects: %@", JSON);
    
    alertShown = false;
    
    //sort the devices into the categories
    [self getWidgets];
    
    [tableview reloadData];
    
    if(firstUpdate == YES)
        firstUpdate = NO;
    
    //reload devices after 20 seconds
    [self performSelector:@selector(updateDevices:) withObject:[NSNumber numberWithLong:timestamp] afterDelay:20.0];
}

//method for redirect if outdoor is used
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSMutableURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == YES)
        return [authent handleAuthentication:request withResponse:response];
    else
        return request;
}

//method to set the rooms button selected
-(IBAction)roomsSelected:(id)sender
{
    currentButton = NSLocalizedString(@"Rooms", @"");
    UIColor *color = self.navigationController.navigationBar.tintColor;
    [roomsButton setTintColor:color];
    [typesButton setTintColor:nil];
    [tagsButton setTintColor:nil];
    [tableview reloadData];
}

//method to set the types button selected
-(IBAction)typesSelected:(id)sender
{
    currentButton = NSLocalizedString(@"Types", @"");
    UIColor *color = self.navigationController.navigationBar.tintColor;
    [typesButton setTintColor:color];
    [roomsButton setTintColor:nil];
    [tagsButton setTintColor:nil];
    [tableview reloadData];
}

//method to set the tags button selected
-(IBAction)tagsSelected:(id)sender
{
    currentButton = NSLocalizedString(@"Tags", @"");
    UIColor *color = self.navigationController.navigationBar.tintColor;
    [tagsButton setTintColor:color];
    [roomsButton setTintColor:nil];
    [typesButton setTintColor:nil];
    [tableview reloadData];
}

//provide data for sub view
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"pushWidgetDevices"])
    {
        [self.navigationController setToolbarHidden:YES animated:NO];
        ZWayRoomsViewController *destination = segue.destinationViewController;
        
        destination.typesDevices = typeObjects;
        destination.tagsDevices = tagObjects;
        destination.roomDevices = roomObjects;
        destination.selected = currentButton;
        destination.deviceIndex = deviceIndex;
        destination.title = name;
    }
}

//sort devices into categories
- (void)getWidgets
{
    types = [NSMutableArray new];
    tags  = [NSMutableArray new];
    rooms = [NSMutableArray new];
    typeObjects = [NSMutableArray new];
    tagObjects  = [NSMutableArray new];
    roomObjects = [NSMutableArray new];
    roomIDs = [NSMutableArray new];
    ZWDevice *device = [ZWDevice new];
    rooms = handler.locationTitles;
    roomIDs = handler.locationIDs;
    
    //set up the rooms
    for(NSInteger i=0; i<rooms.count; i++)
    {
        NSMutableArray *puffArray = [NSMutableArray new];
        [roomObjects addObject:puffArray];
    }
    
    //sort every device into it´s category e.g.: multiSensor
    for (NSInteger i=0; i<objects.count; i++)
    {
        device = [objects objectAtIndex:i];
        NSString *deviceType = device.deviceType;
        NSArray *deviceTags = [[NSArray alloc]initWithArray:device.tags];
        NSString *location = device.location;
        
        //ignore NULL and system items
        if (deviceType != (id)[NSNull null] && ![deviceType isEqualToString:@"system"] && ![deviceType isEqualToString:@"camera"] && ![deviceType isEqualToString:@"switchRGBW"])
        {
            //sort into existing type array
            if(![types containsObject:deviceType])
            {
                [types addObject:deviceType];
                NSMutableArray *typeDevice = [NSMutableArray new];
                [typeDevice addObject:device];
                [self.typeObjects addObject:typeDevice];
            }
            //or create new type
            else
            {
                NSUInteger index = [types indexOfObject:deviceType];
                NSMutableArray *puffer = [[NSMutableArray alloc]initWithArray:[typeObjects objectAtIndex:index]];
                [puffer addObject:device];
                [typeObjects replaceObjectAtIndex:index withObject:puffer];
            }
        }

        //sort into tags
        for (NSInteger j=0; j<deviceTags.count; j++)
        {
            NSString *tagObject = [deviceTags objectAtIndex:j];
            
            //ignore NULL items
            if(tagObject != (id)[NSNull null])
            {
                //sort into existing category
                if(![tags containsObject:tagObject])
                {
                    [tags addObject:tagObject];
                    NSMutableArray *tagDevice = [NSMutableArray new];
                    [tagDevice addObject:device];
                    [self.tagObjects addObject:tagDevice];
                }
                //or create a new one
                else
                {
                    NSUInteger index = [tags indexOfObject:tagObject];
                    NSMutableArray *puffer = [[NSMutableArray alloc]initWithArray:[tagObjects objectAtIndex:index]];
                    [puffer addObject:device];
                    [tagObjects replaceObjectAtIndex:index withObject:puffer];
                }
            }
        }
        
        //ignore NULL locations
        if(location != (id)[NSNull null])
        {
            for (int j=0; j<rooms.count; j++)
            {
                //sort devices into the rooms
                if([[roomIDs objectAtIndex:j] isEqual:location])
                {
                    NSUInteger index = [roomIDs indexOfObject:location];
                    NSMutableArray *puffer = [[NSMutableArray alloc]initWithArray:[roomObjects objectAtIndex:index]];
                    [puffer addObject:device];
                    [roomObjects replaceObjectAtIndex:index withObject:puffer];
                }
            }
        }
    }
}

//all categories have the same height
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

//one section in tableview
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

//hide tableview if no objects are found for the category or return the selected count
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if([currentButton isEqualToString:NSLocalizedString(@"Rooms", @"")])
    {
        if(rooms.count == 0)
        {
            tableview.hidden = YES;
            noItemsLabel.hidden = NO;
        }
        else
        {
            tableview.hidden = NO;
            noItemsLabel.hidden = YES;
        }
        return rooms.count;
    }
    else if([currentButton isEqualToString:NSLocalizedString(@"Types", @"")])
    {
        if(types.count == 0)
        {
            tableview.hidden = YES;
            noItemsLabel.hidden = NO;
        }
        else
        {
            tableview.hidden = NO;
            noItemsLabel.hidden = YES;
        }
        return types.count;
    }
    else
    {
        if(tags.count == 0)
        {
            tableview.hidden = YES;
            noItemsLabel.hidden = NO;
        }
        else
        {
            tableview.hidden = NO;
            noItemsLabel.hidden = YES;
        }
        return tags.count;
    }

}

//display cells depending on the button selected
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    //show rooms
    if([currentButton isEqualToString:NSLocalizedString(@"Rooms", @"")] && rooms.count != 0)
    {
        cell.textLabel.text = [rooms objectAtIndex:indexPath.row];
    }
    //show types
    else if([currentButton isEqualToString:NSLocalizedString(@"Types", @"")] && types.count != 0)
    {
        cell.textLabel.text = [self smoothTitles:[types objectAtIndex:indexPath.row]];
    }
    //show tags
    else if([currentButton isEqualToString:NSLocalizedString(@"Tags", @"")] && tags.count != 0)
    {
        cell.textLabel.text = [tags objectAtIndex:indexPath.row];
    }
    //display default cells (ob´nly called when an unusual situation appears)
    else
    {
        cell.textLabel.text = NSLocalizedString(@"NoDevices", @"Message that no devices were found");
    }
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    return cell;
}

//go to subview if a category is selected
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    deviceIndex = [NSNumber numberWithInteger:indexPath.row];
    
    //provide array for subview
    if([currentButton isEqualToString:NSLocalizedString(@"Rooms", @"")])
        name = [rooms objectAtIndex:indexPath.row];
    else if([currentButton isEqualToString:NSLocalizedString(@"Types", @"")])
        name = [self smoothTitles:[types objectAtIndex:indexPath.row]];
    else
        name = [tags objectAtIndex:indexPath.row];

    [self performSegueWithIdentifier:@"pushWidgetDevices" sender:self];
}

//smooth out the title to look better
- (NSString *)smoothTitles:(NSString *)title
{
    if([title isEqualToString:@"battery"])
    {
        return NSLocalizedString(@"Battery", @"Battery devices");
    }
    else if ([title isEqualToString:@"sensorMultilevel"])
    {
        return NSLocalizedString(@"MultiSensor", @" Multi sensor devices");
    }
    else if ([title isEqualToString:@"sensorBinary"])
    {
        return NSLocalizedString(@"BinarySensor", @"Binary sensot devices");
    }
    else if ([title isEqualToString:@"switchBinary"])
    {
        return NSLocalizedString(@"BinarySwitch", @"Switches devices");
    }
    else if ([title isEqualToString:@"switchMultilevel"])
    {
        return NSLocalizedString(@"MultiSwitch", @"scalable devices");
    }
    else if ([title isEqualToString:@"doorlock"])
    {
        return NSLocalizedString(@"Doorlock", @"Doorlock devices");
    }
    else if ([title isEqualToString:@"thermostat"])
    {
        return NSLocalizedString(@"Thermostat", @"Thermostat devices");
    }
    else if ([title isEqualToString:@"fan"])
    {
        return NSLocalizedString(@"Fan", @"fan devices");
    }
    else if ([title isEqualToString:@"meter"])
    {
        return NSLocalizedString(@"Meter", @"meter devices");
    }
    else if([title isEqualToString:@"toggleButton"])
    {
        return NSLocalizedString(@"Scene", @"Scene Buttons");
    }
    else
        return title;
}

//save data when leaving the view
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
        
    NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:objects];
    NSData *encodedJSON = [NSKeyedArchiver archivedDataWithRootObject:JSON];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (objects) {
        [defaults setObject:encodedObject forKey:@"Devices"];
        objects = nil;
    }
    if(JSON)
    {
        [defaults setObject:encodedJSON forKey:@"JSON"];
        JSON = nil;
    }
}

@end
