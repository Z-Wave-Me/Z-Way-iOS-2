//
//  ZWDeviceItemThermostat.m
//  Z-Way
//
//  Created by Alex Skalozub on 8/27/12.
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

#import "ZWDeviceItemThermostat.h"
#import "ZWayAppDelegate.h"

@implementation ZWDeviceItemThermostat

@synthesize modeView = _modeView;
@synthesize currentState;

+ (ZWDeviceItemThermostat*)device
{
    NSArray *a = [[NSBundle mainBundle] loadNibNamed:@"ZWDeviceItemThermostat" owner:nil options:nil];
    return [a objectAtIndex:0];
}

- (void)dealloc
{
    self.modeView = nil;
    states = nil;
}

- (void)currentTitle
{
    if([currentState isEqualToString:@"0"])
        [self.modeView setTitle:NSLocalizedString(@"Off", @"") forState:UIControlStateNormal];
    else if ([currentState isEqualToString:@"1"])
        [self.modeView setTitle:NSLocalizedString(@"Heat", @"") forState:UIControlStateNormal];
    else if ([currentState isEqualToString:@"2"])
        [self.modeView setTitle:NSLocalizedString(@"Cool", @"") forState:UIControlStateNormal];
    else if ([currentState isEqualToString:@"3"])
        [self.modeView setTitle:NSLocalizedString(@"Auto", @"") forState:UIControlStateNormal];
    else if ([currentState isEqualToString:@"5"])
        [self.modeView setTitle:NSLocalizedString(@"Resume", @"") forState:UIControlStateNormal];
    else if ([currentState isEqualToString:@"6"])
        [self.modeView setTitle:NSLocalizedString(@"FanOnly", @"") forState:UIControlStateNormal];
    else if ([currentState isEqualToString:@"8"])
        [self.modeView setTitle:NSLocalizedString(@"DryAir", @"") forState:UIControlStateNormal];
}

- (void)updateState
{
    currentState = [NSString stringWithFormat:@"%@", [self.device.metrics objectForKey:@"currentMode"]];
    [self currentTitle];
    self.currentState = currentState;
    
    states = [NSMutableArray new];
    [states addObject:NSLocalizedString(@"Off", @"")];
    [states addObject:NSLocalizedString(@"Heat", @"")];
    [states addObject:NSLocalizedString(@"Cool", @"")];
    [states addObject:NSLocalizedString(@"Auto", @"")];
    [states addObject:NSLocalizedString(@"Resume", @"")];
    [states addObject:NSLocalizedString(@"FanOnly", @"")];
    [states addObject:NSLocalizedString(@"DryAir", @"")];
}

- (void)hideControls:(BOOL)editing
{
    if(editing == YES)
        self.modeView.hidden = YES;
    else
        self.modeView.hidden = NO;
}

- (void)setMode:(id)sender
{
    ZWPickerPopup *pickerPopup = [[ZWPickerPopup alloc] initWithParent:(UIView *)sender];
    UIPickerView *modePicker = pickerPopup.picker;
    
    modePicker.showsSelectionIndicator = YES;
    modePicker.dataSource = self;
    modePicker.delegate = self;
    modePicker.tag = 1;
    
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [window addSubview:pickerPopup];
    [pickerPopup becomeFirstResponder];
    [pickerPopup addTarget:self action:@selector(setModeDone:) forControlEvents:UIControlEventValueChanged];
}

- (void)setModeDone:(ZWPickerPopup*)sender
{
    [sender removeTarget:self action:@selector(setModeDone:) forControlEvents:UIControlEventValueChanged];
    [sender removeFromSuperview];
    
    [self sendRequest];
}

- (void)sendRequest
{
    currentState = self.currentState;
    NSString *url;
    
    if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == NO)
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/ZAutomation/api/v1/devices/%@/command/setMode?mode=%@", ZWayAppDelegate.sharedDelegate.profile.indoorUrl, self.device.deviceId, currentState]];
    else
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://find.z-wave.me/ZAutomation/api/v1/devices/%@/command/setMode?mode=%@", self.device.deviceId, currentState]];
    
    [self createRequestWithURL];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 7;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [states objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if([[states objectAtIndex:row] isEqualToString:NSLocalizedString(@"Off", @"")])
        currentState = @"0";
    else if([[states objectAtIndex:row] isEqualToString:NSLocalizedString(@"Heat", @"")])
        currentState = @"1";
    else if([[states objectAtIndex:row] isEqualToString:NSLocalizedString(@"Cool", @"")])
        currentState = @"2";
    else if([[states objectAtIndex:row] isEqualToString:NSLocalizedString(@"Auto", @"")])
        currentState = @"3";
    else if([[states objectAtIndex:row] isEqualToString:NSLocalizedString(@"Resume", @"")])
        currentState = @"5";
    else if([[states objectAtIndex:row] isEqualToString:NSLocalizedString(@"FanOnly", @"")])
        currentState = @"6";
    else if([[states objectAtIndex:row] isEqualToString:NSLocalizedString(@"DryAir", @"")])
        currentState = @"8";
    
    [self currentTitle];
}

@end
