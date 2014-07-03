//
//  ZWDeviceItemScene.h
//  ZWay
//
//  Created by Lucas von Hacht on 03/07/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZWDeviceItem.h"

@interface ZWDeviceItemScene : ZWDeviceItem

@property (nonatomic, strong)IBOutlet UIButton *toggleButton;

- (IBAction)triggerToggle:(id)sender;

+ (ZWDeviceItemScene*)device;

@end
