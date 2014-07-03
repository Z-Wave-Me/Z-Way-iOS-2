//
//  ZWDevice.h
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/16/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZWDataHandler.h"
#import "ZWDeviceItem.h"
#import "ZWayAppDelegate.h"

@class ZWDeviceItem;

@interface ZWDevice : NSObject<NSCoding>
{
    NSString *deviceType;
    NSString *deviceId;
    NSString *location;
    NSDictionary *metrics;
    NSArray *tags;
    NSString *updateTime;
}

@property(strong, nonatomic) NSString *deviceType;
@property(strong, nonatomic) NSString *deviceId;
@property(strong, nonatomic) NSString *location;
@property(strong, nonatomic) NSArray *tags;
@property(strong, nonatomic) NSDictionary *metrics;
@property(strong, nonatomic) NSString *updateTime;

- (NSMutableArray*)updateObjects:(NSMutableArray*)array withDict:(NSMutableDictionary*) object;
- (ZWDeviceItem*)createUIforTableView:(UITableView*)tableView atPos:(NSIndexPath*)indexPath;
- (CGFloat)height;

@end
