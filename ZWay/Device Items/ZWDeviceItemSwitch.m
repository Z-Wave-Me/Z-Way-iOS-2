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
    //check if it´s a normal binary switch
    if([self.device.deviceType isEqualToString:@"switchBinary"])
    {
        NSString *on = [self.device.metrics valueForKey:@"level"];
        //check if it´s on
        if ([on isEqualToString:@"on"])
            [self.switchView setOn:YES];
        else
            [self.switchView setOn:NO];
    }
    //else it may be a doorlock
    else if([self.device.deviceType isEqualToString:@"doorlock"])
    {
        //set it on when it´s open
        if ([[self.device.metrics valueForKey:@"mode"]isEqualToString:@"open"])
            [self.switchView setOn:YES];
        else
            [self.switchView setOn:NO];
    }
}

//hide switch if it´s editing
- (void)hideControls:(BOOL)editing
{
    if(editing == YES)
        self.switchView.hidden = YES;
    else
        self.switchView.hidden = NO;
}

- (void)switchChanged:(id)sender
{
    BOOL value = self.switchView.isOn;
    NSString *state;
    
    //check if switch was turned on or off
    if (value == YES)
    {
        //check if it´s a doorlock
        if([self.device.deviceType isEqualToString:@"doorlock"])
            state = @"open";
        //must be a switch
        else
            state = @"on";
    }
    else
    {
        //check if it´s a doorlock
        if([self.device.deviceType isEqualToString:@"doorlock"])
            state = @"close";
        //must be a switch
        else
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
