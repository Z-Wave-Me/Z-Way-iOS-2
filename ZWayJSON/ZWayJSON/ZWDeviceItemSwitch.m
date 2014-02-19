//
//  ZWDeviceItemSwitch.m
//  Z-Way
//
//  Created by Alex Skalozub on 8/18/12.
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

#import "ZWDeviceItemSwitch.h"
#import "ZWayAppDelegate.h"

@implementation ZWDeviceItemSwitch

@synthesize switchView = _switchView;

+ (ZWDeviceItemSwitch*)device
{
    NSArray *a = [[NSBundle mainBundle] loadNibNamed:@"ZWDeviceItemSwitch" owner:nil options:nil];
    return [a objectAtIndex:0];
}

- (void)dealloc
{
    self.nameView = nil;
    self.switchView = nil;
}

- (void)updateState
{
    NSString *on = [self.device.metrics objectForKey:@"level"];
    if ([on integerValue] == 255)
        [self.switchView setOn:YES];
    else
        [self.switchView setOn:NO];
}

- (void)switchChanged:(id)sender
{
    BOOL value = self.switchView.isOn;
    NSString *state;
    if (value == YES) {
        state = @"on";
    }
    else
        state = @"off";

    NSString *url = [NSString stringWithFormat:@"http://%@/ZAutomation/api/v1/devices/%@/command/%@", ZWayAppDelegate.sharedDelegate.profile.indoorUrl, self.device.deviceId, state];
    [self createRequestWithURL:url];
}

@end
