//
//  ZWDeviceItemSensorBinary.m
//  Z-Way
//
//  Created by Alex Skalozub on 8/22/12.
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

#import "ZWDeviceItemSensorBinary.h"
#import "ZWayAppDelegate.h"
@implementation ZWDeviceItemSensorBinary

@synthesize valueView = _valueView;

+ (ZWDeviceItemSensorBinary*)device
{
    NSArray *a = [[NSBundle mainBundle] loadNibNamed:@"ZWDeviceItemSensorBinary" owner:nil options:nil];
    return [a objectAtIndex:0];
}

- (void)dealloc
{
    self.valueView = nil;
}

- (void)refresh:(id)sender
{
    
}

@end
