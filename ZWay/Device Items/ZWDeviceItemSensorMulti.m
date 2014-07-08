//
//  ZWDeviceItemSensorMulti.m
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

#import "ZWDeviceItemSensorMulti.h"
#import "ZWayAppDelegate.h"

@implementation ZWDeviceItemSensorMulti

@synthesize slider, switchButton;

+ (ZWDeviceItemSensorMulti*)device
{
    NSArray *a = [[NSBundle mainBundle] loadNibNamed:@"ZWDeviceItemDimmer" owner:nil options:nil];
    return [a objectAtIndex:0];
}

//set the slider to the current value
- (void)updateState
{
    NSString *value = [self.device.metrics valueForKey:@"level"];
    if([value integerValue] > 100)
        value = @"100";
        
    [slider setValue:[value integerValue]];
    
    //check if it´s on
    NSString *on = [self.device.metrics valueForKey:@"level"];
    if ([on integerValue] > 0)
        [self.switchButton setOn:YES];
    else
        [self.switchButton setOn:NO];
}

//hide the slider when editing
- (void)hideControls:(BOOL)editing
{
    if (editing == YES)
        self.slider.hidden = YES;
    else
        self.slider.hidden = NO;
}

//send a command when the slider was moved
- (void)handleValueChanged:(id)sender event:(id)event {
    UITouch *touchEvent = [[event allTouches] anyObject];
    if (touchEvent.phase == UITouchPhaseEnded)
    {
        NSInteger value = slider.value;
        
        //decide if indoor or outdoor URL should be used
        if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == NO)
            url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/ZAutomation/api/v1/devices/%@/command/exact?level=%ld", ZWayAppDelegate.sharedDelegate.profile.indoorUrl, self.device.deviceId, (long)value]];
        else
            url = [NSURL URLWithString:[NSString stringWithFormat:@"https://find.z-wave.me/ZAutomation/api/v1/devices/%@/command/exact?level=%ld", self.device.deviceId, (long)value]];
        
        //create the request
        [self createRequestWithURL];
    }
}

- (void)switchValueChanged:(id)sender
{
    BOOL value = self.switchButton.isOn;
    NSString *state;
    
    //check if switch was turned on or off
    if (value == YES)
    {
        state = @"on";
    }
    else
    {
        state = @"off";
    }
    
    //decide if outdoor or indoor URL should be used
    if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == NO)
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/ZAutomation/api/v1/devices/%@/command/%@", ZWayAppDelegate.sharedDelegate.profile.indoorUrl, self.device.deviceId, state]];
    else
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://find.z-wave.me/ZAutomation/api/v1/devices/%@/command/%@", self.device.deviceId, state]];
    
    //create the request
    [self createRequestWithURL];
}

@end
