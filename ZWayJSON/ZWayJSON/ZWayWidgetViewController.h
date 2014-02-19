//
//  ZWaySecondViewController.h
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/15/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZWayDashboardViewController.h"

@interface ZWayWidgetViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, NSCoding, UIGestureRecognizerDelegate>
{
    NSMutableArray *types;
    NSMutableArray *rooms;
    NSMutableArray *tags;
    NSMutableArray *tagObjects;
    NSMutableArray *roomObjects;
    NSMutableArray *typeObjects;
    NSMutableArray *objects;
    NSDictionary *JSON;
    NSNumber *deviceIndex;
}

@property (strong, nonatomic) NSString *currentButton;
@property (strong, nonatomic) NSMutableArray *rooms;
@property (strong, nonatomic) NSMutableArray *types;
@property (strong, nonatomic) NSMutableArray *tags;
@property (strong, nonatomic) NSMutableArray *roomObjects;
@property (strong, nonatomic) NSMutableArray *typeObjects;
@property (strong, nonatomic) NSMutableArray *tagObjects;
@property (strong, nonatomic) IBOutlet UITableView *tableview;
@property (nonatomic, strong) NSMutableArray *objects;
@property (nonatomic, strong) NSDictionary *JSON;
@property (nonatomic, strong) NSNumber *deviceIndex;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *roomsButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *typesButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *tagsButton;
@property (strong, nonatomic) IBOutlet UILabel *noItemsLabel;


-(IBAction)roomsSelected:(id)sender;
-(IBAction)typesSelected:(id)sender;
-(IBAction)tagsSelected:(id)sender;
-(void)getWidgets;

@end
