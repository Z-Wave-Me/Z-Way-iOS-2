//
//  ZWDeviceItemBattery.m
//  Z-Way
//
//  Created by Alex Skalozub on 9/4/12.
//  Copyright (c) 2012 Alex Skalozub.
//
//  Z-Way for iOS is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//  
//  Z-Way for iOS is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
// 
//  You should have received a copy of the GNU General Public License
//  along with Z-Way for iOS. If not, see <http://www.gnu.org/licenses/>
//

#import "ZWDeviceItemBattery.h"
#import "ZWayAppDelegate.h"

@implementation ZWDeviceItemBattery

@synthesize valueView = _valueView;

+ (ZWDeviceItemBattery*)device
{
    NSArray *a = [[NSBundle mainBundle] loadNibNamed:@"ZWDeviceItemBattery" owner:nil options:nil];
    return [a objectAtIndex:0];
}

- (void)updateState
{
    NSString *value = [NSString stringWithFormat:@"%@", [self.device.metrics objectForKey:@"level"]];
    NSString *scale = [self.device.metrics objectForKey:@"scaleTitle"];
    [self.valueView setText:value];
    [self.scale setText:scale];
}

- (void)dealloc
{
    self.valueView = nil;
}

@end
