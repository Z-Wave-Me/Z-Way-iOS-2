//
//  ZWayFirstViewController.h
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/15/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"
#import "ZWDevice.h"
#import "ZWaySpeech.h"
#import <Slt/Slt.h>
#import <OpenEars/FliteController.h>

@interface ZWayDashboardViewController : UIViewController<NSCoding, UITableViewDelegate, UITableViewDataSource, NSURLConnectionDataDelegate, NSURLConnectionDelegate, SWTableViewCellDelegate, OpenEarsEventsObserverDelegate>
{
    NSMutableArray *objects;
    BOOL editMode;
    NSMutableData *receivedData;
    BOOL alertShown;
    ZWDevice *notFound;
    ZWDevice *spokenDevice;
    NSString *command;
    NSInteger speechState;
    ZWaySpeech *speech;
    FliteController *fliteController;
    Slt *slt;
    OpenEarsEventsObserver *openEarsEventsObserver;
    PocketsphinxController *pocketSphinxController;
}

@property (nonatomic, strong) IBOutlet UILabel *noItemsLabel;
@property (nonatomic, strong) IBOutlet UITableView *tableview;
@property (strong, nonatomic) FliteController *fliteController;
@property (strong, nonatomic) Slt *slt;
@property (strong, nonatomic) OpenEarsEventsObserver *openEarsEventsObserver;

- (void)updateObjects;
- (void)addDeviceTitles;
- (void)startListening;

@end
