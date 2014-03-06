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
#import "RWKnobControl.h"

@implementation ZWDeviceItemSensorMulti

@synthesize slider;

+ (ZWDeviceItemSensorMulti*)device
{
    NSArray *a = [[NSBundle mainBundle] loadNibNamed:@"ZWDeviceItemSensorMulti" owner:nil options:nil];
    return [a objectAtIndex:0];
}

/*- (id)init
{
    self = [super init];
    if(self)
    {
        _knobControl = [[RWKnobControl alloc] initWithFrame:self.placeholder.bounds];
        [self.placeholder addSubview:_knobControl];
        
        _knobControl.lineWidth = 4.0;
        _knobControl.pointerLength = 8.0;
    }
        
    return self;
}*/

- (void)updateState
{
    NSString *value = [self.device.metrics objectForKey:@"level"];
    [slider setValue:[value integerValue]];
}

- (void)hideControls:(BOOL)editing
{
    if (editing == YES)
        self.slider.hidden = YES;
    else
        self.slider.hidden = NO;
}

- (void)movedSlider:(id)sender
{
    NSInteger value = slider.value;
    NSString *url;
    
    if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == NO)
        url = [NSString stringWithFormat:@"http://%@/ZAutomation/api/v1/devices/%@/command/exact?level=%ld", ZWayAppDelegate.sharedDelegate.profile.indoorUrl, self.device.deviceId, (long)value];
    else
        url = [NSString stringWithFormat:@"http://%@/ZAutomation/api/v1/devices/%@/command/exact?level=%ld", ZWayAppDelegate.sharedDelegate.profile.outdoorUrl, self.device.deviceId, (long)value];
    
    [self createRequestWithURL:url];
}

@end
