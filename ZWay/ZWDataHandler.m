//
//  ZWDataHandler.m
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/17/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import "ZWDataHandler.h"
#import "ZWayAppDelegate.h"

@implementation ZWDataHandler

@synthesize locationTitles;
@synthesize locationIDs;
@synthesize authent;

//get the timestamp from the JSON data
-(NSUInteger)getTimestamp:(NSDictionary *)dictionary firstTime:(BOOL)first
{
    NSString *updateTime = [[dictionary objectForKey:@"data"] valueForKey:@"updateTime"];
    NSUInteger timestamp = [updateTime integerValue];

    return timestamp;
}

- (void)setUpAuth
{
    authent = [ZWayAuthentification new];
}

//load the locations
- (void)getLocations
{
    NSURL *url;
    NSMutableURLRequest *request;
    
    //check if outdoor is used
    if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == YES)
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://find.z-wave.me/ZAutomation/api/v1/locations"]];
    //or use indoor
    else
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/ZAutomation/api/v1/locations", ZWayAppDelegate.sharedDelegate.profile.indoorUrl]];
    
    request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:30.0];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [request setValue:@"gzip, deflate, sdch" forHTTPHeaderField:@"Accept-Encoding"];
    
    //create the connection and check if it was successful
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if(!connection && alertShown == false)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:NSLocalizedString(@"UpdateError", @"Message that an error occured during the update") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [alert show];
        alertShown = true;
        receivedData = nil;
    }
}

//method to check the response
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    receivedData = [NSMutableData new];
    [receivedData setLength:0];
    
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    int responseStatusCode = [httpResponse statusCode];
    
    if(responseStatusCode == 200)
        alertShown = false;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    connection = nil;
    receivedData = nil;
    
    //alert the user if an error occured
    if(alertShown == false)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:[error localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [alert show];
        NSLog(@"Error: %@", [error description]);
        alertShown = true;
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError *error;
    locationTitles = [NSMutableArray new];
    locationIDs = [NSMutableArray new];
    self.locationTitles = [NSMutableArray new];
    self.locationIDs = [NSMutableArray new];
    
    //extract locations from parsed JSON
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:receivedData options:NSJSONReadingMutableContainers error:&error];
    NSArray *temp = [dict objectForKey:@"data"];
    
    //check all devices and sort them into the rooms
    for(NSInteger i=0; i<temp.count; i++)
    {
        NSString *locationTitle = [[temp objectAtIndex:i] objectForKey:@"title"];
        NSString *locationID = [[temp objectAtIndex:i] objectForKey:@"id"];
        
        //add the location if it isn´t already contained
        if(![locationTitles containsObject:locationTitle])
            [locationTitles addObject:locationTitle];
        
        //add the location ID if it sin´t already contained
        if(![locationIDs containsObject:locationID])
            [locationIDs addObject:locationID];
    }
    self.locationTitles = locationTitles;
    self.locationIDs = locationIDs;
    
    //reload the data after 30 seconds
    [self performSelector:@selector(getLocations) withObject:nil afterDelay:10.0];
}

//method to redirect in outdoor use
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSMutableURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == YES)
        return [authent handleAuthentication:request withResponse:response];
    else
        return request;
}

@end
