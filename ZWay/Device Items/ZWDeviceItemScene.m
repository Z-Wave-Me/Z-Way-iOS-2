//
//  ZWDeviceItemScene.m
//  ZWay
//
//  Created by Lucas von Hacht on 03/07/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import "ZWDeviceItemScene.h"

@implementation ZWDeviceItemScene


//load xib for scene
+ (ZWDeviceItemScene*)device
{
    NSArray *a = [[NSBundle mainBundle] loadNibNamed:@"ZWDeviceItemScene" owner:nil options:nil];
    return [a objectAtIndex:0];
}

- (void)dealloc
{
    self.nameView = nil;
    self.toggleButton = nil;
}

//sent command when toggle button is pressed
-(IBAction)triggerToggle:(id)sender
{
    //decide if outdoor or indoor URL should be used
    if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == NO)
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/ZAutomation/api/v1/devices/%@/command/on", ZWayAppDelegate.sharedDelegate.profile.indoorUrl, self.device.deviceId]];
    else
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://find.z-wave.me/ZAutomation/api/v1/devices/%@/command/on", self.device.deviceId]];
    
    //create the request
    [self createRequestWithURL];
}

- (void)updateState
{
    //No need to update since it only trigger actions but gives no feedback
}

//hide switch if it´s editing
- (void)hideControls:(BOOL)editing
{
    if(editing == YES)
        self.toggleButton.hidden = YES;
    else
        self.toggleButton.hidden = NO;
}


@end
