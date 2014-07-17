//
//  ZWayAppDelegate.h
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/15/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CMProfile.h"
#import "ZWDataStore.h"
#import "ZWayLanguage.h"

@interface ZWayAppDelegate : UIResponder <UIApplicationDelegate>
{
    UIWindow *window;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ZWDataStore *dataStore;
@property (strong, nonatomic) CMProfile *profile;
@property (readonly) BOOL settingsLocked;

+ (ZWayAppDelegate*)sharedDelegate;
- (void)useColorTheme:(NSString*)theme;
- (void)useLanguage;
- (void)testOutdoor;

@end
