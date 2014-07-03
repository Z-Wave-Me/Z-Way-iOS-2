//
//  ZWayNotificationViewController.h
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/21/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZWayAuthentification.h"

@interface ZWayNotificationViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, NSCoding, NSURLConnectionDataDelegate, NSURLConnectionDelegate>
{
    NSDictionary *JSON;
    NSMutableData *notificationData;
    NSMutableArray *notifications;
    NSNumber *currentTimestamp;
    ZWayAuthentification *authent;
    NSMutableDictionary *cellField;
    BOOL firstUpdate;
    BOOL alertShown;
}

@property (strong, nonatomic) IBOutlet UILabel *noItemsLabel;
@property (strong, nonatomic) IBOutlet UITableView *tableview;
@property (strong, nonatomic) ZWayAuthentification *authent;

- (void)getNotifications:(NSNumber*)timestamp;

@end
