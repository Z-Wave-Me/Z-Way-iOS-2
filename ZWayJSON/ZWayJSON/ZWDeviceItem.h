//
//  ZWDeviceItem.h
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/20/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZWDevice.h"
#import "SWTableViewCell.h"

@class ZWDevice;

@interface ZWDeviceItem : SWTableViewCell<NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
    NSMutableData *receivedData;
    NSInteger attempts;
    NSURL *url;
}

@property (strong, nonatomic) IBOutlet UILabel *nameView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) ZWDevice *device;

- (void)setDisplayName;
- (void)hideControls:(BOOL)editing;
- (void)updateState;
- (void)createRequestWithURL;

@end
