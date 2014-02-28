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
