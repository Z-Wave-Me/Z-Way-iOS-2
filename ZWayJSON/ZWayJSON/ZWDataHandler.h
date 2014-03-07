//
//  ZWDataHandler.h
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/17/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZWDevice.h"

@interface ZWDataHandler : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate>
{
    NSMutableData *receivedData;
    NSMutableArray *locations;
    int alertShown;
    NSInteger attempts;
}

@property (nonatomic, strong) NSMutableArray *locations;

- (NSUInteger)getTimestamp:(NSDictionary *)dictionary;
- (void)getLocations;

@end
