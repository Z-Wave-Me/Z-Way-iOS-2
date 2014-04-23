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
#import "ZWDeviceItemThermostat.h"
#import "ZWDeviceItemSwitch.h"
#import "ZWDeviceItemFan.h"
#import "ZWDevice.h"
#import "ZWDataHandler.h"
#import "ZWayRoomsViewController.h"
#import "ZWayNotificationViewController.h"
#import "NSData+Base64.h"
#import "ZWaySpeech.h"
#import <OpenEars/PocketsphinxController.h>
#import <OpenEars/FliteController.h>
#import <OpenEars/LanguageModelGenerator.h>
#import <OpenEars/OpenEarsLogging.h>
#import <OpenEars/AcousticModel.h>

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
@synthesize fliteController;
@synthesize slt;
@synthesize openEarsEventsObserver;


- (void)viewDidLoad
{
    toolbar.delegate = self;
    [self.navigationController setToolbarHidden:NO];
    [self setToolbarItems:[NSArray arrayWithObjects:self.tagsButton, self.typesButton, self.roomsButton, nil] animated:NO];
    
    currentButton = @"Rooms";
    roomsButton.title = NSLocalizedString(@"Rooms", @"");
    typesButton.title = NSLocalizedString(@"Types", @"");
    tagsButton.title = NSLocalizedString(@"Tags", @"");
    noItemsLabel.text = NSLocalizedString(@"NoDevices", @"");
    UIColor *color = self.navigationController.navigationBar.tintColor;
    [self.toolbar setTintColor:color];
    [self roomsSelected:self];
    handler = [ZWDataHandler new];
    [handler getLocations];
    [self updateDevices:0];
    
    UIPinchGestureRecognizer *pinchRecognizer = [UIPinchGestureRecognizer new];
    [pinchRecognizer addTarget:self action:@selector(startListening)];
    [self.openEarsEventsObserver setDelegate:self];
    
    speech = [ZWaySpeech new];
    [speech fixCommands];
}

- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

- (void)startListening
{
    if([ZWayAppDelegate.sharedDelegate.profile.useSpeech boolValue] == YES)
    {
        [self addDeviceTitles];
        [speech setUpSpeech];
        [self.fliteController say:@"Please name the device" withVoice:self.slt];
    }
}

- (void)updateDevices:(NSInteger)timestamp
{
    NSURL *url;
    NSMutableURLRequest *request;
    
    if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == YES)
    {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://find.z-wave.me/ZAutomation/api/v1/devices"]];
        request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:30.0];
        
        [request setHTTPMethod:@"GET"];
        [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
        [request setValue:@"gzip, deflate, sdch" forHTTPHeaderField:@"Accept-Encoding"];
    }
    else
    {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/ZAutomation/api/v1/devices?since=%u", ZWayAppDelegate.sharedDelegate.profile.indoorUrl, 0]];
        request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:30.0];
        
        [request setHTTPMethod:@"GET"];
        [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
        [request setValue:@"gzip, deflate, sdch" forHTTPHeaderField:@"Accept-Encoding"];
    }
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if(!connection && alertShown == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:NSLocalizedString(@"UpdateError", @"Message that an error occured during the update") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [alert show];
        alertShown = 1;
        receivedObjects = nil;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    receivedObjects = [NSMutableData new];
    [receivedObjects setLength:0];
    
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    int responseStatusCode = [httpResponse statusCode];

    if(responseStatusCode == 200)
        alertShown = 0;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedObjects appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    connection = nil;
    receivedObjects = nil;
    
    if(alertShown == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:[error localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [alert show];
        NSLog(@"Error: %@", [error description]);
        alertShown = 1;
    }
    
    [self performSelector:@selector(updateDevices:) withObject:[NSNumber numberWithInt:0] afterDelay:10.0];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    attempts = 0;
    ZWDevice *device = [ZWDevice new];
    NSError *error;
    
    JSON = [NSJSONSerialization JSONObjectWithData:receivedObjects options:NSJSONReadingMutableContainers error:&error];
    objects = [[JSON objectForKey:@"data"] objectForKey:@"devices"];
    int timestamp = [handler getTimestamp:JSON];
    
    //or set it
    if(objects.count == 0)
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSData *encodedJSON = [defaults objectForKey:@"JSON"];
        NSData *encodedObjects = [defaults objectForKey:@"Devices"];
    
        objects = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObjects];
        JSON = [NSKeyedUnarchiver unarchiveObjectWithData:encodedJSON];

        timestamp = [handler getTimestamp:JSON];
        
        if(alertShown == 0)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:NSLocalizedString(@"UpdateError", @"Message that an error occured during the update") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
            [alert show];
            alertShown = 1;
        }
    }
    else
        objects = [[device updateObjects:objects WithDict:nil] mutableCopy];
    
    alertShown = 0;
    [self getWidgets];
    
    [tableview reloadData];
    [self performSelector:@selector(updateDevices:) withObject:[NSNumber numberWithInt:timestamp] afterDelay:10.0];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSMutableURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == YES)
    {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        int responseStatusCode = [httpResponse statusCode];
    
        NSURL *url;
    
        if(responseStatusCode >= 300 && responseStatusCode <= 400 && attempts == 1)
        {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"http://find.z-wave.me/ZAutomation/api/v1/devices"]];
            request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:30.0];
        
            [request setHTTPMethod:@"GET"];
            [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
            [request setValue:@"gzip, deflate, sdch" forHTTPHeaderField:@"Accept-Encoding"];
            attempts = 2;
            return request;
        }
        else if(attempts == 0)
        {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"http://find.z-wave.me/zboxweb"]];
            request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:30.0];
        
            NSString *postString = [NSString stringWithFormat:@"act=login&login=%@&pass=%@", ZWayAppDelegate.sharedDelegate.profile.userLogin, ZWayAppDelegate.sharedDelegate.profile.userPassword];
            NSData *myRequestData = [postString dataUsingEncoding: NSUTF8StringEncoding];
        
            [request setHTTPMethod:@"POST"];
            [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
            [request setValue:@"gzip, deflate, sdch" forHTTPHeaderField:@"Accept-Encoding"];
            [request setValue:[NSString stringWithFormat:@"%d", [myRequestData length]] forHTTPHeaderField:@"Content-length"];
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
            [request setHTTPBody:myRequestData];
            attempts = 1;
            return request;
        }
        else
        {
            if(alertShown == 0)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Wrong Credentials" message:NSLocalizedString(@"CredentialError", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles: nil];
                [alert show];
                alertShown = 1;
            }
            [connection cancel];
            return nil;
        }
    }
    else
        return request;
}

-(IBAction)roomsSelected:(id)sender
{
    currentButton = @"Rooms";
    UIColor *color = self.navigationController.navigationBar.tintColor;
    [roomsButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    [roomsButton setTintColor:[UIColor whiteColor]];
    [typesButton setTintColor:nil];
    [typesButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:nil, NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    [tagsButton setTintColor:nil];
    [tagsButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:nil, NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    [tableview reloadData];
}

-(IBAction)typesSelected:(id)sender
{
    currentButton = @"Types";
    UIColor *color = self.navigationController.navigationBar.tintColor;
    [typesButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    [typesButton setTintColor:[UIColor whiteColor]];
    [roomsButton setTintColor:nil];
    [roomsButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:nil, NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    [tagsButton setTintColor:nil];
    [tagsButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:nil, NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    [tableview reloadData];
}

-(IBAction)tagsSelected:(id)sender
{
    currentButton = @"Tags";
    UIColor *color = self.navigationController.navigationBar.tintColor;
    [tagsButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    [tagsButton setTintColor:[UIColor whiteColor]];
    [roomsButton setTintColor:nil];
    [roomsButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:nil, NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    [typesButton setTintColor:nil];
    [typesButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:nil, NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    [tableview reloadData];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"pushWidgetDevices"])
    {
        ZWayRoomsViewController *destination = segue.destinationViewController;
        
        destination.typesDevices = typeObjects;
        destination.tagsDevices = tagObjects;
        destination.roomDevices = roomObjects;
        destination.selected = currentButton;
        destination.deviceIndex = deviceIndex;
        destination.title = name;
    }
}


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
    
    for (NSInteger i=0; i<objects.count; i++)
    {
        device = [objects objectAtIndex:i];
        NSString *deviceType = device.deviceType;
        NSArray *deviceTags = [[NSArray alloc]initWithArray:device.tags];
        NSString *location = device.location;
        
        if (deviceType != (id)[NSNull null] && ![deviceType isEqualToString:@"system"])
        {
            if(![types containsObject:deviceType])
            {
                [types addObject:deviceType];
                NSMutableArray *typeDevice = [NSMutableArray new];
                [typeDevice addObject:device];
                [self.typeObjects addObject:typeDevice];
            }
            else
            {
                NSUInteger index = [types indexOfObject:deviceType];
                NSMutableArray *puffer = [[NSMutableArray alloc]initWithArray:[typeObjects objectAtIndex:index]];
                [puffer addObject:device];
                [typeObjects replaceObjectAtIndex:index withObject:puffer];
            }
        }

        for (NSInteger j=0; j<deviceTags.count; j++)
        {
            NSString *tagObject = [deviceTags objectAtIndex:j];
            
            if(tagObject != (id)[NSNull null])
            {
                if(![tags containsObject:tagObject])
                {
                    [tags addObject:tagObject];
                    NSMutableArray *tagDevice = [NSMutableArray new];
                    [tagDevice addObject:device];
                    [self.tagObjects addObject:tagDevice];
                }
                else
                {
                    NSUInteger index = [tags indexOfObject:tagObject];
                    NSMutableArray *puffer = [[NSMutableArray alloc]initWithArray:[tagObjects objectAtIndex:index]];
                    [puffer addObject:device];
                    [tagObjects replaceObjectAtIndex:index withObject:puffer];
                }
            }
        }
        
        if(location != (id)[NSNull null])
        {
            for (int j=0; j<rooms.count; j++)
            {
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


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if([currentButton isEqualToString:@"Rooms"])
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
    else if([currentButton isEqualToString:@"Types"])
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

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";

    if([currentButton isEqualToString:@"Rooms"] && rooms.count != 0)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        cell.textLabel.text = [rooms objectAtIndex:indexPath.row];
        return cell;
    }
    else if([currentButton isEqualToString:@"Types"] && types.count != 0)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        cell.textLabel.text = [types objectAtIndex:indexPath.row];
        return cell;
    }
    else if(tags.count != 0)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        cell.textLabel.text = [tags objectAtIndex:indexPath.row];
        return cell;
    }
    else
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        cell.textLabel.text = NSLocalizedString(@"NoDevices", @"Message that no devices were found");
        return cell;
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    deviceIndex = [NSNumber numberWithInt:indexPath.row];
    
    if([currentButton isEqualToString:@"Rooms"])
        name = [rooms objectAtIndex:indexPath.row];
    else if([currentButton isEqualToString:@"Types"])
        name = [types objectAtIndex:indexPath.row];
    else
        name = [tags objectAtIndex:indexPath.row];

    
    [self performSegueWithIdentifier:@"pushWidgetDevices" sender:self];
}

- (void)addDeviceTitles
{
    NSMutableArray *deviceTitles = [NSMutableArray new];
    
    for(int i=0; i<objects.count; i++)
    {
        ZWDevice *device = [objects objectAtIndex:i];
        NSDictionary *dict = device.metrics;
        NSString *title = [[dict valueForKey:@"title"] uppercaseString];
        if(![deviceTitles containsObject:title])
            [deviceTitles addObject:title];
    }
    [speech updateCommands:deviceTitles];
}

- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID
{
    for(int i=0; i<objects.count; i++)
    {
        ZWDevice *device = [objects objectAtIndex:i];
        NSString *title = [[device.metrics objectForKey:@"title"] uppercaseString];
        if([hypothesis isEqualToString:title])
        {
            spokenDevice = device;
            speechState = 1;
        }
        else if([speech.words containsObject:hypothesis])
        {
            command = hypothesis;
            speechState = 0;
        }
    }
    
    if([spokenDevice isKindOfClass:[ZWDeviceItemFan class]])
    {
        ZWDeviceItemFan *fanItem = (ZWDeviceItemFan*)spokenDevice;
        if([command isEqualToString:@"AUTOLOW"])
            fanItem.currentState = @"0";
        else if([command isEqualToString:@"ONLOW"])
            fanItem.currentState = @"1";
        else if([command isEqualToString:@"AUTOHIGH"])
            fanItem.currentState = @"2";
        else if([command isEqualToString:@"ONHIGH"])
            fanItem.currentState = @"3";
        
        [fanItem sendRequest];
    }
    else if ([spokenDevice isKindOfClass:[ZWDeviceItemSwitch class]])
    {
        ZWDeviceItemSwitch *switchItem = (ZWDeviceItemSwitch*)spokenDevice;
        if([command isEqualToString:@"ON"])
        {
            [switchItem.switchView setOn:YES animated:YES];
            [switchItem switchChanged:self];
        }
        else if([command isEqualToString:@"OFF"])
        {
            [switchItem.switchView setOn:NO animated:YES];
            [switchItem switchChanged:self];
        }
    }
    else if([spokenDevice isKindOfClass:[ZWDeviceItemThermostat class]])
    {
        ZWDeviceItemThermostat *therItem = (ZWDeviceItemThermostat*)spokenDevice;
        if([command isEqualToString:@"AUTOLOW"])
            therItem.currentState = @"0";
        else if([command isEqualToString:@"ONLOW"])
            therItem.currentState = @"1";
        else if([command isEqualToString:@"AUTOHIGH"])
            therItem.currentState = @"2";
        else if([command isEqualToString:@"ONHIGH"])
            therItem.currentState = @"3";
        
        [therItem sendRequest];
    }
    else
    {
        [self.fliteController say:@"Not a valid command" withVoice:self.slt];
    }
}

- (void)pocketsphinxDidDetectFinishedSpeech
{
    if(speechState == 1)
    {
        [self.fliteController say:@"Please name the command" withVoice:self.slt];
        speechState = 0;
    }
    else if (speechState == 0)
        [speech stopListening];
}

- (FliteController *)fliteController {
	if (fliteController == nil) {
		fliteController = [[FliteController alloc] init];
	}
	return fliteController;
}

- (Slt *)slt {
	if (slt == nil) {
		slt = [[Slt alloc] init];
	}
	return slt;
}

- (OpenEarsEventsObserver *)openEarsEventsObserver {
	if (openEarsEventsObserver == nil) {
		openEarsEventsObserver = [[OpenEarsEventsObserver alloc] init];
	}
	return openEarsEventsObserver;
}

- (PocketsphinxController *)pocketSphinxController
{
    if(pocketSphinxController == nil)
        pocketSphinxController = [PocketsphinxController new];
    
    return pocketSphinxController;
}

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
