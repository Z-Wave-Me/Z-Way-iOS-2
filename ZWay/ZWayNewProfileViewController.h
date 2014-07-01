//
//  ZWayNewProfileViewController.h
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/24/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CMProfile.h"

@interface ZWayNewProfileViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
    CMProfile *_profile;
    NSMutableDictionary *_fields;
    NSArray *_fieldsOrder;
    NSString *oldIP;
}

@property (strong, nonatomic) IBOutlet UITableView *tableview;
@property (strong, nonatomic) NSString *editing;
@property (strong, nonatomic) NSString *loaded;


- (void)testConnection:(NSString*)field With:(UITextField*)connection;
- (void)store;
- (void)deleteProfile;
- (NSString*)conformToProfile:(NSString*)string;

@end
