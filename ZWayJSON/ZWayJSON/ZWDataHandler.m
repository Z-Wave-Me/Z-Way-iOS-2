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

//get the timestamp from the JSON data
-(NSUInteger)getTimestamp:(NSDictionary *)dictionary
{
    NSString *updateTime = [[dictionary objectForKey:@"data"] objectForKey:@"updateTime"];
    NSUInteger timestamp = [updateTime integerValue];
    
    NSString *changed = [[dictionary objectForKey:@"data"] objectForKey:@"structureChanged"];
    if ([changed integerValue] == 1)
    {
        timestamp = 0;
    }
    return timestamp;
}

- (void)getLocations
{
    NSURL *url;
    NSMutableURLRequest *request;
    
    if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == YES)
    {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://find.z-wave.me/ZAutomation/api/v1/locations"]];
        request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:30.0];
        
        [request setHTTPMethod:@"GET"];
        [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
        [request setValue:@"gzip, deflate, sdch" forHTTPHeaderField:@"Accept-Encoding"];
    }
    else
    {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/ZAutomation/api/v1/locations", ZWayAppDelegate.sharedDelegate.profile.indoorUrl]];
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
        receivedData = nil;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    receivedData = [NSMutableData new];
    [receivedData setLength:0];
    
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    int responseStatusCode = [httpResponse statusCode];
    
    if(responseStatusCode == 200)
        alertShown = 0;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    connection = nil;
    receivedData = nil;
    
    if(alertShown == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:[error localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [alert show];
        NSLog(@"Error: %@", [error description]);
        alertShown = 1;
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    attempts = 0;
    NSError *error;
    locationTitles = [NSMutableArray new];
    locationIDs = [NSMutableArray new];
    self.locationTitles = [NSMutableArray new];
    self.locationIDs = [NSMutableArray new];
    
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:receivedData options:NSJSONReadingMutableContainers error:&error];
    NSArray *temp = [dict objectForKey:@"data"];
    for(NSInteger i=0; i<temp.count; i++)
    {
        NSString *locationTitle = [[temp objectAtIndex:i] objectForKey:@"title"];
        NSString *locationID = [[temp objectAtIndex:i] objectForKey:@"id"];
        
        if(![locationTitles containsObject:locationTitle])
            [locationTitles addObject:locationTitle];
        
        if(![locationIDs containsObject:locationID])
            [locationIDs addObject:locationID];
    }
    self.locationTitles = locationTitles;
    self.locationIDs = locationIDs;
    
    [self performSelector:@selector(getLocations) withObject:nil afterDelay:10.0];
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
            url = [NSURL URLWithString:[NSString stringWithFormat:@"http://find.z-wave.me/ZAutomation/api/v1/locations"]];
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
            [connection cancel];
            return nil;
        }
    }
    else
        return request;
}

@end
