//
//  ZWayFirstViewController.h
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/15/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZWDevice.h"
#import "ZWayAuthentification.h"

@interface ZWayDashboardViewController : UIViewController<NSCoding, UITableViewDelegate, UITableViewDataSource, NSURLConnectionDataDelegate, NSURLConnectionDelegate>
{
    NSMutableArray *objects;
    BOOL editMode;
    NSMutableData *receivedData;
    BOOL alertShown;
    ZWDevice *notFound;
    ZWDevice *spokenDevice;
    ZWDevice *currentdevice;
    NSString *command;
}

@property (nonatomic, strong) IBOutlet UILabel *noItemsLabel;
@property (nonatomic, strong) IBOutlet UITableView *tableview;

- (void)updateObjects;

@end
