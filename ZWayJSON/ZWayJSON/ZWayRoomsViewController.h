//
//  ZWayRoomsViewController.h
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/22/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZWayWidgetViewController.h"
#import "ZWDeviceItem.h"
#import "ZWDevice.h"
#import "SWTableViewCell.h"

@interface ZWayRoomsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, NSCoding, SWTableViewCellDelegate>
{
    NSMutableArray *roomDevices;
    NSMutableArray *tagsDevices;
    NSMutableArray *typesDevices;
    NSString *selected;
    NSNumber *deviceIndex;
    NSMutableArray *displayDevices;
    NSMutableArray *objectsToDash;
}

@property(nonatomic, strong) NSMutableArray *roomDevices;
@property(nonatomic, strong) NSMutableArray *tagsDevices;
@property(nonatomic, strong) NSMutableArray *typesDevices;
@property(nonatomic, strong) NSString *selected;
@property(nonatomic, strong) NSNumber *deviceIndex;
@property(nonatomic, strong) NSMutableArray *displayDevices;
@property(nonatomic, strong) IBOutlet UITableView *tableview;
@property(nonatomic, strong) IBOutlet UILabel *noItemsLabel;

- (BOOL)moveToDash:(ZWDevice*)device;
- (void)registerCells;
- (void)changeToNormal:(SWTableViewCell*)cell;

@end
