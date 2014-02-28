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


- (void)viewDidLoad
{
    currentButton = @"Rooms";
    roomsButton.title = NSLocalizedString(@"Rooms", @"");
    typesButton.title = NSLocalizedString(@"Types", @"");
    tagsButton.title = NSLocalizedString(@"Tags", @"");
    noItemsLabel.text = NSLocalizedString(@"NoDevices", @"");
    UIColor *color = self.navigationController.navigationBar.tintColor;
    [self.toolbar setTintColor:color];
    [self roomsSelected:self];
    [self updateDevices:0];
}

- (void)updateDevices:(NSInteger)timestamp
{
    NSURL *url;
    
    if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == NO)
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/ZAutomation/api/v1/devices?since=%u", ZWayAppDelegate.sharedDelegate.profile.indoorUrl, 0]];
    else
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/ZAutomation/api/v1/devices?since=%u", ZWayAppDelegate.sharedDelegate.profile.outdoorUrl, 0]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:60.0];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [request setValue:@"gzip, deflate, sdch" forHTTPHeaderField:@"Accept-Encoding"];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if(!connection && alertShown == NO)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:NSLocalizedString(@"UpdateError", @"Message that an error occured during the update") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [alert show];
        alertShown = YES;
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
        alertShown = NO;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedObjects appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    connection = nil;
    receivedObjects = nil;
    
    if(alertShown == NO)
    {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:[error localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
    [alert show];
    alertShown = YES;
    }
    
    [self performSelector:@selector(updateDevices:) withObject:[NSNumber numberWithInt:0] afterDelay:10.0];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    ZWDataHandler *handler = [ZWDataHandler new];
    ZWDevice *device = [ZWDevice new];
    NSError *error;
    
    JSON = [NSJSONSerialization JSONObjectWithData:receivedObjects options:NSJSONReadingMutableContainers error:&error];
    objects = [[JSON objectForKey:@"data"] objectForKey:@"devices"];
    int timestamp = [handler getTimestamp:JSON];
    /*NSLog(@"JSON: %@", JSON);
    NSString *responsestring = [[NSString alloc] initWithData:receivedObjects encoding:NSUTF8StringEncoding];
    NSLog(@"%@", responsestring);*/
    
    //or set it
    if(objects.count == 0)
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSData *encodedJSON = [defaults objectForKey:@"JSON"];
        NSData *encodedObjects = [defaults objectForKey:@"Devices"];
        
        objects = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObjects];
        JSON = [NSKeyedUnarchiver unarchiveObjectWithData:encodedJSON];

        timestamp = [handler getTimestamp:JSON];
    }
    else
        objects = [[device updateObjects:objects WithDict:nil] mutableCopy];
    
    alertShown = NO;
    [self getWidgets];
    
    [tableview reloadData];
    [self performSelector:@selector(updateDevices:) withObject:[NSNumber numberWithInt:timestamp] afterDelay:10.0];
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
        if([challenge previousFailureCount] == 0)
        {
            [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
            [challenge.sender useCredential:credentials forAuthenticationChallenge:challenge];
        }
    }
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

-(IBAction)roomsSelected:(id)sender
{
    currentButton = @"Rooms";
    UIColor *color = self.navigationController.navigationBar.tintColor;
    [roomsButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:color, UITextAttributeTextColor, nil] forState:UIControlStateNormal];
    [roomsButton setTintColor:[UIColor whiteColor]];
    [typesButton setTintColor:nil];
    [typesButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:nil, UITextAttributeTextColor, nil] forState:UIControlStateNormal];
    [tagsButton setTintColor:nil];
    [tagsButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:nil, UITextAttributeTextColor, nil] forState:UIControlStateNormal];
    [tableview reloadData];
}

-(IBAction)typesSelected:(id)sender
{
    currentButton = @"Types";
    UIColor *color = self.navigationController.navigationBar.tintColor;
    [typesButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:color, UITextAttributeTextColor, nil] forState:UIControlStateNormal];
    [typesButton setTintColor:[UIColor whiteColor]];
    [roomsButton setTintColor:nil];
    [roomsButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:nil, UITextAttributeTextColor, nil] forState:UIControlStateNormal];
    [tagsButton setTintColor:nil];
    [tagsButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:nil, UITextAttributeTextColor, nil] forState:UIControlStateNormal];
    [tableview reloadData];
}

-(IBAction)tagsSelected:(id)sender
{
    currentButton = @"Tags";
    UIColor *color = self.navigationController.navigationBar.tintColor;
    [tagsButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:color, UITextAttributeTextColor, nil] forState:UIControlStateNormal];
    [tagsButton setTintColor:[UIColor whiteColor]];
    [roomsButton setTintColor:nil];
    [roomsButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:nil, UITextAttributeTextColor, nil] forState:UIControlStateNormal];
    [typesButton setTintColor:nil];
    [typesButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:nil, UITextAttributeTextColor, nil] forState:UIControlStateNormal];
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
    }
}


- (void)getWidgets
{
    types = [NSMutableArray new];
    tags  = [NSMutableArray new];
    typeObjects = [NSMutableArray new];
    tagObjects  = [NSMutableArray new];
    roomObjects = [NSMutableArray new];
    ZWDevice *device = [ZWDevice new];
    ZWDataHandler *handler = [ZWDataHandler new];
    rooms = [[NSMutableArray alloc] initWithArray:[handler getLocations]];
    
    for (NSInteger i=0; i<objects.count; i++)
    {
        device = [objects objectAtIndex:i];
        NSString *deviceType = device.deviceType;
        NSArray *deviceTags = [[NSArray alloc]initWithArray:device.tags];
        NSString *location = device.location;
        
        if (deviceType != (id)[NSNull null])
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
                if([[rooms objectAtIndex:j] isEqualToString:location])
                {
                    NSUInteger index = [rooms indexOfObject:location];
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
    [self performSegueWithIdentifier:@"pushWidgetDevices" sender:self];
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
