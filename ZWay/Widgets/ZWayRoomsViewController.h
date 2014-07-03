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

@interface ZWayRoomsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, NSCoding, UIGestureRecognizerDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate>
{
    NSMutableArray *roomDevices;
    NSMutableArray *tagsDevices;
    NSMutableArray *typesDevices;
    NSString *selected;
    NSNumber *deviceIndex;
    NSMutableArray *displayDevices;
    NSMutableArray *objectsToDash;
    NSMutableData *receivedData;
    ZWayAuthentification *authent;
}

@property(nonatomic, strong) NSMutableArray *roomDevices;
@property(nonatomic, strong) NSMutableArray *tagsDevices;
@property(nonatomic, strong) NSMutableArray *typesDevices;
@property(nonatomic, strong) NSString *selected;
@property(nonatomic, strong) NSNumber *deviceIndex;
@property(nonatomic, strong) NSMutableArray *displayDevices;
@property(nonatomic, strong) IBOutlet UITableView *tableview;
@property(nonatomic, strong) IBOutlet UILabel *noItemsLabel;
@property(nonatomic, strong) ZWayAuthentification *authent;

- (BOOL)moveToDash:(ZWDevice*)device;
-(void)onLongPress:(UILongPressGestureRecognizer*)pGesture;
-(void)handleTapGesture:(UITapGestureRecognizer*)tGesture;

@end
