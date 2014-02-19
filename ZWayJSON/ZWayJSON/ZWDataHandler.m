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

//method to get the JSON data
- (NSDictionary*)getJSON:(NSUInteger)timestamp
{
    NSDictionary *JSONobject;
    NSString *URL = [NSString stringWithFormat:@"http://%@/ZAutomation/api/v1/devices?since=%u", ZWayAppDelegate.sharedDelegate.profile.indoorUrl, timestamp];
    NSData *zwayData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:URL]];
    
    if(zwayData != nil){
        NSError *error;
        JSONobject = [NSJSONSerialization JSONObjectWithData:zwayData options:NSJSONReadingMutableContainers error:&error];
    }
    
    return JSONobject;
}

//get the timestamp from the JSON data
-(NSUInteger)getTimestamp:(NSDictionary *)dictionary
{
    NSString *updateTime = [[dictionary objectForKey:@"data"] objectForKey:@"updateTime"];
    NSUInteger timestamp = [updateTime integerValue];
    return timestamp;
}

- (NSDictionary*)getNotifications:(NSInteger)timestamp
{
    NSDictionary *notifications = [NSDictionary new];
    NSString *URL = [NSString stringWithFormat:@"http://%@/ZAutomation/api/v1/notifications?since=%u",ZWayAppDelegate.sharedDelegate.profile.indoorUrl, timestamp];
    NSData *notificationData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:URL]];
    
    if(notificationData != nil)
    {
        NSError *error;
        notifications = [NSJSONSerialization JSONObjectWithData:notificationData options:NSJSONReadingMutableContainers error:&error];
    }
    
    return notifications;
}

- (NSMutableArray*)getLocations
{
    NSMutableArray *locations = [NSMutableArray new];
    NSString *URL = [NSString stringWithFormat:@"http://%@/ZAutomation/api/v1/locations", ZWayAppDelegate.sharedDelegate.profile.indoorUrl];
    NSData *locationData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:URL]];
    
    if(locationData != nil)
    {
        NSError *error;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:locationData options:NSJSONReadingMutableContainers error:&error];
        NSArray *temp = [dict objectForKey:@"data"];
        for(NSInteger i=0; i<temp.count; i++)
        {
            NSString *locationString = [[temp objectAtIndex:i] objectForKey:@"title"];
            [locations addObject:locationString];
        }
    }
    return locations;
}

@end
