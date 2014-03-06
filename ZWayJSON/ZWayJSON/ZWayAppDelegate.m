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
    
    [self.window makeKeyAndVisible];
    [self useColorTheme:self.profile.theme];
    [self testOutdoor];
    
    return YES;
}

- (void)testOutdoor
{
    Reachability *reachability = [Reachability reachabilityForLocalWiFi];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    if (networkStatus == ReachableViaWiFi)
        self.profile.useOutdoor = [NSNumber numberWithBool:NO];
    else
        self.profile.useOutdoor = [NSNumber numberWithBool:YES];
    
    [self performSelector:@selector(testOutdoor) withObject:nil afterDelay:10.0];
}

- (void)useColorTheme:(NSString*)theme
{
    if([theme isEqualToString:NSLocalizedString(@"Red", @"")])
    {
        [[UINavigationBar appearance] setTintColor:[UIColor redColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor redColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor redColor]];
    }
    else if([theme isEqualToString:NSLocalizedString(@"Blue", @"")])
    {
        [[UINavigationBar appearance] setTintColor:[UIColor blueColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor blueColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor blueColor]];
    }
    else if([theme isEqualToString:NSLocalizedString(@"Orange", @"")])
    {
        [[UINavigationBar appearance] setTintColor:[UIColor orangeColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor orangeColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor orangeColor]];
    }
    else if([theme isEqualToString:NSLocalizedString(@"Purple", @"")])
    {
        [[UINavigationBar appearance] setTintColor:[UIColor purpleColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor purpleColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor purpleColor]];
    }
    else if([theme isEqualToString:NSLocalizedString(@"Cyan", @"")])
    {
        [[UINavigationBar appearance] setTintColor:[UIColor cyanColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor cyanColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor cyanColor]];
    }
    else
    {
        [[UINavigationBar appearance] setTintColor:[UIColor cyanColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor cyanColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor cyanColor]];
    }
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

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // try local address on activate
    if (self.profile != nil)
    {
        @synchronized(self.profile)
        {
            self.profile.useOutdoor = [NSNumber numberWithBool:NO];
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    
}

@end
