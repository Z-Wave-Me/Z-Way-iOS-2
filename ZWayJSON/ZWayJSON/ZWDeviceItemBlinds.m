//
//  ZWDeviceItemBlinds.m
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

#import "ZWDeviceItemBlinds.h"
#import "ZWayAppDelegate.h"

@implementation ZWDeviceItemBlinds

@synthesize buttonsView = _buttonsView;
@synthesize sliderView = _sliderView;

+ (ZWDeviceItemBlinds*)device
{
    NSArray *a = [[NSBundle mainBundle] loadNibNamed:@"ZWDeviceItemBlinds" owner:nil options:nil];
    return [a objectAtIndex:0];
}

- (void)dealloc
{
    self.buttonsView = nil;
    self.sliderView = nil;
}

- (NSString*)refreshingStateKey
{
    return @"level";
}

- (void)setValue:(id)sender
{
    int value = (int)roundf(self.sliderView.value);
}

- (void)pressButton:(id)sender
{
    _isHeld = NO;
}

- (void)pressAndHold:(id)sender
{
    _isHeld = YES;
}

- (void)releaseButton:(id)sender
{
    _isHeld = NO;
}

@end
