//
//  ZWayFirstViewController.h
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/15/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"

@interface ZWayDashboardViewController : UIViewController<NSCoding, UITableViewDelegate, UITableViewDataSource, NSURLConnectionDataDelegate, NSURLConnectionDelegate, SWTableViewCellDelegate>
{
    NSMutableArray *objects;
    BOOL editMode;
    NSMutableData *receivedData;
    BOOL alertShown;
}

@property (nonatomic, strong) IBOutlet UILabel *noItemsLabel;
@property (nonatomic, strong) IBOutlet UITableView *tableview;

- (void)updateObjects;

@end
