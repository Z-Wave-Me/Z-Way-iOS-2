//
//  ZWDeviceItem.h
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/20/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZWDevice.h"
#import "ZWayAuthentification.h"

@class ZWDevice;

@interface ZWDeviceItem : UITableViewCell<NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
    NSMutableData *receivedData;
    NSURL *url;
    ZWayAuthentification *authent;
}

@property (strong, nonatomic) IBOutlet UILabel *nameView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) ZWDevice *device;
@property (strong, nonatomic) ZWayAuthentification *authent;

- (void)setDisplayName;
- (void)hideControls:(BOOL)editing;
- (void)updateState;
- (void)createRequestWithURL;

@end
