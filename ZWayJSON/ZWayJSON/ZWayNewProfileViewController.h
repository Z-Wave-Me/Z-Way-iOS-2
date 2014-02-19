//
//  ZWayNewProfileViewController.h
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/24/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CMProfile.h"
#import "Reachability.h"

@interface ZWayNewProfileViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
    CMProfile *_profile;
    NSMutableDictionary *_fields;
    NSArray *_fieldsOrder;
    Reachability *reachableFoo;
}

- (IBAction)testConnection:(NSString*)field With:(UITextField*)connection;
- (IBAction)store:(id)sender;
- (NSString*)conformToProfile:(NSString*)string;
@property (strong, nonatomic) IBOutlet UITableView *tableview;
@property (strong, nonatomic) NSString *editing;
@property (strong, nonatomic) NSString *loaded;

@end
