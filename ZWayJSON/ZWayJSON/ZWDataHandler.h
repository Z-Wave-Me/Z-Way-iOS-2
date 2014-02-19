//
//  ZWDataHandler.h
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/17/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZWDataHandler : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate>

- (NSDictionary*)getJSON:(NSUInteger)timestamp;
- (NSUInteger)getTimestamp:(NSDictionary *)dictionary;
- (NSDictionary*)getNotifications:(NSInteger)timestamp;
- (NSMutableArray*)getLocations;

@end
