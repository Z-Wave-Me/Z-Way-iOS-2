//
//  ZWayNewProfileViewController.h
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/24/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CMProfile.h"
#import "ZWayLanguage.h"

@interface ZWayNewProfileViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate, UIPickerViewDataSource, UIPickerViewDelegate>
{
    CMProfile *_profile;
    NSMutableDictionary *_fields;
    NSArray *_fieldsOrder;
    NSString *oldIP;
    NSArray *colors;
    NSArray *languages;
    BOOL languageSelecting;
}

@property (strong, nonatomic) IBOutlet UITableView *tableview;
@property (strong, nonatomic) NSString *editing;
@property (strong, nonatomic) NSString *loaded;
@property (strong, nonatomic) UIPickerView *picker;

- (void)testConnection:(NSString*)field With:(NSString*)connection;
- (IBAction)checkedBox:(id)sender;
- (void)store;
- (void)deleteProfile;
- (void)bringUpPickerViewWithRow:(NSIndexPath*)indexPath;
- (void)hidePickerView;
- (void)updateColor:(NSString*)color;
- (void)updateLanguage:(NSString *)language;
- (NSString*)conformToProfile:(NSString*)string;
- (NSString*)languageTitle;

@end
