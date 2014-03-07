//
//  ZWayNotificationViewController.h
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/21/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZWayNotificationViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, NSCoding, NSURLConnectionDataDelegate, NSURLConnectionDelegate>
{
    NSDictionary *JSON;
    NSMutableData *notificationData;
    NSMutableArray *notifications;
    NSInteger currentTimestamp;
    BOOL alertShown;
}

@property (strong, nonatomic) IBOutlet UILabel *noItemsLabel;

- (void)getNotifications:(NSInteger)timestamp;

@end
