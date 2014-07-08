//
//  ZWayAppDelegate.m
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/15/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import "ZWayAppDelegate.h"
#import "ZWDataStore.h"
#import "ZWayProfilesViewController.h"
#import "Reachability.h"

@implementation ZWayAppDelegate

@synthesize window = _window;
@synthesize dataStore = _dataStore;

+ (ZWayAppDelegate*)sharedDelegate
{
    return [[UIApplication sharedApplication] delegate];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.dataStore = [[ZWDataStore alloc] init];
    self.profile = nil;
    
    //load the current profile
    NSURL *plistPath = [[self.dataStore applicationDocumentsDirectory] URLByAppendingPathComponent:@"settings.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath.path])
    {
        NSArray* array = [[NSArray alloc] initWithContentsOfURL:plistPath];
        NSString* profileName = [[array objectAtIndex:0] valueForKey:@"profile"];
        if (profileName != nil && profileName.length > 0)
        {
            self.profile = [self.dataStore getProfile:profileName];
        }
        
        NSNumber* locked = [[array objectAtIndex:0] valueForKey:@"settingsLocked"];
        _settingsLocked = (locked != nil && [locked boolValue]);
    }
    
    //remove back button title
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, -60)
                                                         forBarMetrics:UIBarMetricsDefault];
    //start the app
    [self.window makeKeyAndVisible];
    [self useColorTheme:self.profile.theme];
    [self testOutdoor];
    
    return YES;
}

//check for local WiFi
- (void)testOutdoor
{
    Reachability *reachability = [Reachability reachabilityForLocalWiFi];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    
    //if we have it use indoor URL
    if (networkStatus == ReachableViaWiFi)
        self.profile.useOutdoor = [NSNumber numberWithBool:NO];
    //if not use outdoor URL
    else
        self.profile.useOutdoor = [NSNumber numberWithBool:YES];
    
    //check again after 20 seconds
    [self performSelector:@selector(testOutdoor) withObject:nil afterDelay:20.0];
}

- (void)useColorTheme:(NSString*)theme
{
    //check which color was selected and set all color elements to it
    if([theme isEqualToString:NSLocalizedString(@"Red", @"")])
    {
        [[UINavigationBar appearance] setBarTintColor:[UIColor redColor]];
        [[UIToolbar appearance] setBarTintColor:[UIColor redColor]];
        [[UITabBar appearance] setTintColor:[UIColor redColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor redColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor redColor]];
        [[UITabBar appearance] setTintColor:[UIColor redColor]];
    }
    else if([theme isEqualToString:NSLocalizedString(@"Blue", @"")])
    {
        [[UINavigationBar appearance] setBarTintColor:[UIColor blueColor]];
        [[UIToolbar appearance] setBarTintColor:[UIColor blueColor]];
        [[UITabBar appearance] setTintColor:[UIColor blueColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor blueColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor blueColor]];
        [[UITabBar appearance] setTintColor:[UIColor blueColor]];
    }
    else if([theme isEqualToString:NSLocalizedString(@"Orange", @"")])
    {
        [[UINavigationBar appearance] setBarTintColor:[UIColor orangeColor]];
        [[UIToolbar appearance] setBarTintColor:[UIColor orangeColor]];
        [[UITabBar appearance] setTintColor:[UIColor orangeColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor orangeColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor orangeColor]];
        [[UITabBar appearance] setTintColor:[UIColor orangeColor]];
    }
    else if([theme isEqualToString:NSLocalizedString(@"Purple", @"")])
    {
        [[UINavigationBar appearance] setBarTintColor:[UIColor purpleColor]];
        [[UIToolbar appearance] setBarTintColor:[UIColor purpleColor]];
        [[UITabBar appearance] setTintColor:[UIColor purpleColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor purpleColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor purpleColor]];
        [[UITabBar appearance] setTintColor:[UIColor purpleColor]];
    }
    else if([theme isEqualToString:NSLocalizedString(@"Brown", @"")])
    {
        [[UINavigationBar appearance] setBarTintColor:[UIColor brownColor]];
        [[UIToolbar appearance] setBarTintColor:[UIColor brownColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor brownColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor brownColor]];
        [[UITabBar appearance] setTintColor:[UIColor brownColor]];
    }
    else if([theme isEqualToString:NSLocalizedString(@"Cyan", @"")])
    {
        [[UINavigationBar appearance] setBarTintColor:[UIColor cyanColor]];
        [[UIToolbar appearance] setBarTintColor:[UIColor cyanColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor cyanColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor cyanColor]];
        [[UITabBar appearance] setTintColor:[UIColor cyanColor]];
    }
    else if([theme isEqualToString:NSLocalizedString(@"Green", @"")])
    {
        [[UINavigationBar appearance] setBarTintColor:[UIColor greenColor]];
        [[UIToolbar appearance] setBarTintColor:[UIColor greenColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor greenColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor greenColor]];
        [[UITabBar appearance] setTintColor:[UIColor greenColor]];
    }
    else if([theme isEqualToString:NSLocalizedString(@"Magenta", @"")])
    {
        [[UINavigationBar appearance] setBarTintColor:[UIColor magentaColor]];
        [[UIToolbar appearance] setBarTintColor:[UIColor magentaColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor magentaColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor magentaColor]];
        [[UITabBar appearance] setTintColor:[UIColor magentaColor]];
    }
    else if([theme isEqualToString:NSLocalizedString(@"Yellow", @"")])
    {
        [[UINavigationBar appearance] setBarTintColor:[UIColor yellowColor]];
        [[UIToolbar appearance] setBarTintColor:[UIColor yellowColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor yellowColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor yellowColor]];
        [[UITabBar appearance] setTintColor:[UIColor yellowColor]];
    }
    else
    {
        [[UINavigationBar appearance] setBarTintColor:[UIColor blueColor]];
        [[UIToolbar appearance] setBarTintColor:[UIColor blueColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor blueColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor blueColor]];
        [[UITabBar appearance] setTintColor:[UIColor blueColor]];
    }
    
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UIToolbar appearance] setTintColor:[UIColor whiteColor]];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    
}

@end
