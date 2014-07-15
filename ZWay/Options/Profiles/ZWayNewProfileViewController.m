//
//  ZWayNewProfileViewController.m
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/24/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import "ZWayNewProfileViewController.h"
#import "ZWDataStore.h"
#import "CMProfile.h"
#import "ZWayAppDelegate.h"

@interface ZWayNewProfileViewController ()

@end

@implementation ZWayNewProfileViewController

@synthesize tableview;
@synthesize editing;
@synthesize loaded;
@synthesize picker;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.tabBarController.tabBar setTranslucent:NO];
    
    ZWDataStore *store = ZWDataStore.store;
    
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setOpaque:YES];
    [self.tabBarController.tabBar setTranslucent:NO];
    
    //decide if profile is new or editing
    if(![editing isEqualToString:@"YES"])
    {
        //create a new profile
        NSEntityDescription *profileEntity = [NSEntityDescription entityForName:@"Profile" inManagedObjectContext:store.managedObjectContext];
        
        CMProfile *profile = [[CMProfile alloc] initWithEntity:profileEntity insertIntoManagedObjectContext:store.managedObjectContext];
        //set default name and outdoor URL
        profile.name = @"Name";
        profile.language = nil;
        profile.theme = NSLocalizedString(@"Default", @"");
        profile.showErrors = [NSNumber numberWithBool:YES];
        profile.showWarnings = [NSNumber numberWithBool:NO];
        profile.showNotifications = [NSNumber numberWithBool:YES];
        [store saveContext];
        self.navigationItem.title =  NSLocalizedString(@"NewProfile", @"New Profile title");
        _profile = profile;
        ZWayAppDelegate.sharedDelegate.profile = _profile;
    }
    else
        //load profile info when editing
        _profile = ZWayAppDelegate.sharedDelegate.profile;
    
    //decide the order of cells
    _fields = [NSMutableDictionary dictionary];
    [_fields setObject:[[[NSBundle mainBundle] loadNibNamed:@"ZWTextEditCell" owner:self options:nil] objectAtIndex:0] forKey:@"name"];
    [_fields setObject:[[[NSBundle mainBundle] loadNibNamed:@"ZWUrlEditCell" owner:self options:nil] objectAtIndex:0] forKey:@"indoorUrl"];
    [_fields setObject:[[[NSBundle mainBundle] loadNibNamed:@"ZWTextEditCell" owner:self options:nil] objectAtIndex:0] forKey:@"userLogin"];
    [_fields setObject:[[[NSBundle mainBundle] loadNibNamed:@"ZWPasswordCell" owner:self options:nil] objectAtIndex:0] forKey:@"userPassword"];
    [_fields setObject:[[[NSBundle mainBundle] loadNibNamed:@"ZWTextEditCell" owner:self options:nil] objectAtIndex:0] forKey:@"theme"];
    [_fields setObject:[[[NSBundle mainBundle] loadNibNamed:@"ZWTextEditCell" owner:self options:nil] objectAtIndex:0] forKey:@"language"];
    [_fields setObject:[[[NSBundle mainBundle] loadNibNamed:@"ZWCheckBox" owner:self options:nil] objectAtIndex:0] forKey:@"warnings"];
    [_fields setObject:[[[NSBundle mainBundle] loadNibNamed:@"ZWCheckBox" owner:self options:nil] objectAtIndex:0] forKey:@"errors"];
    [_fields setObject:[[[NSBundle mainBundle] loadNibNamed:@"ZWCheckBox" owner:self options:nil] objectAtIndex:0] forKey:@"notifications"];
    
    _fieldsOrder = [NSMutableArray arrayWithObjects:@"name", @"indoorUrl", @"userLogin", @"userPassword", @"theme", @"language", @"warnings", @"errors", @"notifications", nil];
    
    //set up color and language arrays
    colors = [NSArray arrayWithObjects:NSLocalizedString(@"Red", @"Red"), NSLocalizedString(@"Blue", @"Blue"), NSLocalizedString(@"Orange", @"Orange"), NSLocalizedString(@"Purple", @"Purple"), NSLocalizedString(@"Brown", @""), NSLocalizedString(@"Cyan", @""), NSLocalizedString(@"Green", @""), NSLocalizedString(@"Magenta", @""), NSLocalizedString(@"Yellow", @""), nil];
    
    languages = [NSArray arrayWithObjects:NSLocalizedString(@"German", @"German"), NSLocalizedString(@"English", @"English"), NSLocalizedString(@"Russian", @"Russian"), NSLocalizedString(@"Chinese", @"Chinese"), nil];
    
    //set up picker view for language and color
    picker = [[UIPickerView alloc] initWithFrame:(CGRect){{0, 0}, 320, 480}];
    picker.delegate = self;
    picker.dataSource = self;
    picker.showsSelectionIndicator = YES;
    picker.center = (CGPoint){160, 640};
    picker.hidden = YES;
    [self.view addSubview:picker];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //set localized title
    [self setTitle:NSLocalizedString(@"Options", @"")];
}

- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortrait);
}

// Checks if we have a connection or not
- (void)testConnection:(NSString *)field With:(NSString *)connection
{
    //get current cell
    UITableViewCell *cell = (UITableViewCell*)[tableview viewWithTag:11];
    
    //set up the images for valid or invalid IP
    UIImageView *connected = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"connected-g.png"]];
    UIImageView *fail = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"wrong.png"]];

    //create connection with given IP to see if it works
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", connection]];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:3.0];
    NSError *error;
    NSURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
    //check the response
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger responseStatusCode = [httpResponse statusCode];
    
    //set the fail image for invalid IP
    if(responseStatusCode != 200)
        cell.accessoryView = fail;
    //or the valid image for the valid IP
    else
        cell.accessoryView = connected;
    
    data = nil;
}

//dismiss keyboard when leaving the view
- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    
    _profile = nil;
    self.navigationItem.title = nil;
}

//show keyboard
- (void)keyboardWillShow:(NSNotification *)notification
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_2
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
#endif
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_3_2
        NSValue *keyboardBoundsValue = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
#else
        NSValue *keyboardBoundsValue = [[notification userInfo] objectForKey:UIKeyboardBoundsUserInfoKey];
#endif
        CGRect keyboardBounds;
        [keyboardBoundsValue getValue:&keyboardBounds];
        UIEdgeInsets e = UIEdgeInsetsMake(0, 0, keyboardBounds.size.height, 0);
        [[self tableview] setScrollIndicatorInsets:e];
        [[self tableview] setContentInset:e];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_2
    }
#endif
}

//hide keyboard
- (void)keyboardWillHide
{
    UIEdgeInsets e = UIEdgeInsetsZero;
    [[self tableview] setScrollIndicatorInsets:e];
    [[self tableview] setContentInset:e];
}

//save profile when leaving the view
- (void)viewWillDisappear:(BOOL)animated
{
    [self.view endEditing:YES];
    if (ZWayAppDelegate.sharedDelegate.settingsLocked) return;
    
    [ZWDataStore.store.managedObjectContext processPendingChanges];
    [ZWDataStore.store saveContext];
    
    if (_profile == ZWayAppDelegate.sharedDelegate.profile)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ZWProfileHasChanged" object:nil];
    }
}

- (void)checkedBox:(id)sender
{
    if([(UISwitch *)sender isOn] == NO)
    {
        switch ([(UIButton *)sender tag]) {
            case 5:
                _profile.showWarnings = [NSNumber numberWithBool:NO];
                break;
                
            case 6:
                _profile.showErrors = [NSNumber numberWithBool:NO];
                break;
                
            case 7:
                _profile.showNotifications = [NSNumber numberWithBool:NO];
                break;
        }
    }
    else
    {
        switch ([(UISwitch *)sender tag]) {
            case 5:
                _profile.showWarnings = [NSNumber numberWithBool:YES];
                break;
                
            case 6:
                _profile.showErrors = [NSNumber numberWithBool:YES];
                break;
                
            case 7:
                _profile.showNotifications = [NSNumber numberWithBool:YES];
                break;
        }
    }
    
    [(UIButton *)sender setSelected:![(UIButton *)sender isSelected]];
}

//3 sections in tableview
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 6;
}

//title for sections
- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return NSLocalizedString(@"Name", @"");
        case 1:
            return NSLocalizedString(@"IndoorServer", @"");
        case 2:
            return NSLocalizedString(@"RemoteAccess", @"");
        case 3:
            return NSLocalizedString(@"Color", @"Color Theme");
        case 4:
            return NSLocalizedString(@"Language", @"");
        case 5:
            return NSLocalizedString(@"ToShow", @"Notifications to show");
        default:
            return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return 1;
        case 1:
            return 1;
        case 2:
            return 2;
        case 3:
            return 1;
        case 4:
            return 1;
        case 5:
            return 3;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //set up cells
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    NSString *name;
    NSString *displayName;
    UILabel *label;
    UITextField *editor;
    
    //set titles for rows
    switch (indexPath.section)
    {
        case 0:
            name = @"name";
            displayName = NSLocalizedString(@"Name", @"");
            cell = [_fields objectForKey:name];
            cell.tag = 10;
            label = (UILabel*)[cell viewWithTag:1];
            label.text = displayName;
            editor = (UITextField *)[cell viewWithTag:2];
            editor.text = _profile.name;
            break;
            
        case 1:
            name = @"indoorUrl";
            displayName = NSLocalizedString(@"Home", @"At home");
            cell = [_fields objectForKey:name];
            cell.tag = 11;
            label = (UILabel*)[cell viewWithTag:1];
            label.text = displayName;
            editor = (UITextField *)[cell viewWithTag:2];
            editor.text = _profile.indoorUrl;
            break;
            
        case 2:
        {
            switch (indexPath.row)
            {
                case 0:
                    name = @"userLogin";
                    displayName = NSLocalizedString(@"Login", @"");
                    cell = [_fields objectForKey:name];
                    cell.tag = 12;
                    label = (UILabel*)[cell viewWithTag:1];
                    label.text = displayName;
                    editor = (UITextField *)[cell viewWithTag:2];
                    editor.text = _profile.userLogin;
                    break;
                case 1:
                    name = @"userPassword";
                    displayName = NSLocalizedString(@"Password", @"");
                    cell = [_fields objectForKey:name];
                    cell.tag = 13;
                    label = (UILabel*)[cell viewWithTag:1];
                    label.text = displayName;
                    editor = (UITextField *)[cell viewWithTag:2];
                    editor.text = _profile.userPassword;
                    break;
            }
            break;
        }
            
        case 3:
            name = @"theme";
            displayName = NSLocalizedString(@"Color", @"");
            cell = [_fields objectForKey:name];
            cell.tag = 14;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [cell viewWithTag:2].hidden = NO;
            label = (UILabel*)[cell viewWithTag:1];
            label.text = displayName;
            editor = (UITextField *)[cell viewWithTag:2];
            editor.userInteractionEnabled = NO;
            editor.text = _profile.theme;
            break;
            
        case 4:
            name = @"language";
            displayName = NSLocalizedString(@"Language", @"");
            cell = [_fields objectForKey:name];
            cell.tag = 15;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [cell viewWithTag:2].hidden = NO;
            label = (UILabel*)[cell viewWithTag:1];
            label.text = displayName;
            editor = (UITextField *)[cell viewWithTag:2];
            editor.userInteractionEnabled = NO;
            editor.text = [self languageTitle];
            break;
            
        case 5:
        {
            UISwitch *checkBox = [UISwitch new];
            checkBox.tag = indexPath.section + indexPath.row;
            [checkBox addTarget:self action:@selector(checkedBox:) forControlEvents:UIControlEventValueChanged];
            
            switch (indexPath.row)
            {
                case 0:
                {
                    name = @"warnings";
                    displayName = NSLocalizedString(@"Warnings", @"");
                    cell = [_fields objectForKey:name];
                    cell.tag = 16;
                    cell.textLabel.text = displayName;
                    [checkBox setOn:[_profile.showWarnings boolValue]];
                    cell.accessoryView = checkBox;
                    break;
                }
                    
                case 1:
                {
                    name = @"errors";
                    displayName = NSLocalizedString(@"Errors", @"");
                    cell = [_fields objectForKey:name];
                    cell.tag = 17;
                    cell.textLabel.text = displayName;
                    [checkBox setOn:[_profile.showErrors boolValue]];
                    cell.accessoryView = checkBox;
                    break;
                }
                    
                case 2:
                {
                    name = @"notifications";
                    displayName = NSLocalizedString(@"Notifications", @"");
                    cell = [_fields objectForKey:name];
                    cell.tag = 18;
                    cell.textLabel.text = displayName;
                    [checkBox setOn:[_profile.showNotifications boolValue]];
                    cell.accessoryView = checkBox;
                    break;
                }
            }
        }
        break;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    //set up save and delete button
    UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    saveButton.frame = CGRectMake(0, 0, 280, 40);
    [saveButton setTitle:NSLocalizedString(@"Store", @"Store Data") forState:UIControlStateNormal];
    saveButton.backgroundColor = [UIColor clearColor];
    [saveButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [saveButton addTarget:self action:@selector(store) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    deleteButton.frame = CGRectMake(0, 50, 280, 40);
    [deleteButton setTitle:NSLocalizedString(@"DeleteProfile", @"Delete Profile") forState:UIControlStateNormal];
    deleteButton.backgroundColor = [UIColor clearColor];
    [deleteButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [deleteButton addTarget:self action:@selector(deleteProfile) forControlEvents:UIControlEventTouchUpInside];
    
    //place buttons on bottom
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(20, 0, 280, 200)];
    [footerView addSubview:saveButton];
    [footerView addSubview:deleteButton];
    tableView.tableFooterView = footerView;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 3:
            if(indexPath.row == 0)
            {
                //bring up the color picker
                UITableViewCell *cell = (UITableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
                [cell viewWithTag:2].hidden = YES;
                languageSelecting = NO;
                [picker reloadAllComponents];
                [self bringUpPickerViewWithRow:indexPath];
            }
            break;
            
        case 4:
            if(indexPath.row == 0)
            {
                //bring up the language picker
                UITableViewCell *cell = (UITableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
                [cell viewWithTag:2].hidden = YES;
                languageSelecting = YES;
                [picker reloadAllComponents];
                [self bringUpPickerViewWithRow:indexPath];
            }
            break;
            
        default:
            break;
    }
}

//method to show the picker view
- (void)bringUpPickerViewWithRow:(NSIndexPath *)indexPath
{
    //select first item as default
    [picker selectRow:0 inComponent:0 animated:NO];
    
    //check what cell was selected
    UITableViewCell *currentCellSelected = [self.tableview cellForRowAtIndexPath:indexPath];
    self.tableview.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableview setNeedsDisplay];
    [UIView animateWithDuration:1.0f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         //bring it on top of the selected cell
         self.picker.hidden = NO;
         self.picker.center = (CGPoint){currentCellSelected.frame.size.width/2, currentCellSelected.frame.origin.y+20};
     }
                     completion:nil];
}

//mthod to hide the picker view
- (void)hidePickerView
{
    [UIView animateWithDuration:1.0f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         picker.center = (CGPoint){160, 800};
     }
                     completion:^(BOOL finished)
     {
         picker.hidden = YES;
     }];
    
    //reload data in tableview
    self.tableview.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.tableview setNeedsDisplay];
    [self.tableview reloadData];
}


//method to update the color after being picked
- (void)updateColor:(NSString*)color
{
    //check which color was selected and set all color elements to it
    if([color isEqualToString:NSLocalizedString(@"Red", @"")])
    {
        [[UINavigationBar appearance] setTintColor:[UIColor redColor]];
        [self.navigationController.navigationBar setTintColor:[UIColor redColor]];
        [self.tabBarController.tabBar setTintColor:[UIColor redColor]];
        [[UIToolbar appearance] setTintColor:[UIColor redColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor redColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor redColor]];
    }
    else if([color isEqualToString:NSLocalizedString(@"Blue", @"")])
    {
        [[UINavigationBar appearance] setTintColor:[UIColor blueColor]];
        [self.navigationController.navigationBar setTintColor:[UIColor blueColor]];
        [self.tabBarController.tabBar setTintColor:[UIColor blueColor]];
        [[UIToolbar appearance] setTintColor:[UIColor blueColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor blueColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor blueColor]];
    }
    else if([color isEqualToString:NSLocalizedString(@"Orange", @"")])
    {
        [[UINavigationBar appearance] setTintColor:[UIColor orangeColor]];
        [self.navigationController.navigationBar setTintColor:[UIColor orangeColor]];
        [self.tabBarController.tabBar setTintColor:[UIColor orangeColor]];
        [[UIToolbar appearance] setTintColor:[UIColor orangeColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor orangeColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor orangeColor]];
    }
    else if([color isEqualToString:NSLocalizedString(@"Purple", @"")])
    {
        [[UINavigationBar appearance] setTintColor:[UIColor purpleColor]];
        [self.navigationController.navigationBar setTintColor:[UIColor purpleColor]];
        [self.tabBarController.tabBar setTintColor:[UIColor purpleColor]];
        [[UIToolbar appearance] setTintColor:[UIColor purpleColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor purpleColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor purpleColor]];
    }
    else if([color isEqualToString:NSLocalizedString(@"Brown", @"")])
    {
        [[UINavigationBar appearance] setTintColor:[UIColor brownColor]];
        [self.navigationController.navigationBar setTintColor:[UIColor brownColor]];
        [self.tabBarController.tabBar setTintColor:[UIColor brownColor]];
        [[UIToolbar appearance] setTintColor:[UIColor brownColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor brownColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor brownColor]];
    }
    else if([color isEqualToString:NSLocalizedString(@"Cyan", @"")])
    {
        [[UINavigationBar appearance] setTintColor:[UIColor cyanColor]];
        [self.navigationController.navigationBar setTintColor:[UIColor cyanColor]];
        [self.tabBarController.tabBar setTintColor:[UIColor cyanColor]];
        [[UIToolbar appearance] setTintColor:[UIColor cyanColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor cyanColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor cyanColor]];
    }
    else if([color isEqualToString:NSLocalizedString(@"Green", @"")])
    {
        [[UINavigationBar appearance] setTintColor:[UIColor greenColor]];
        [self.navigationController.navigationBar setTintColor:[UIColor greenColor]];
        [self.tabBarController.tabBar setTintColor:[UIColor greenColor]];
        [[UIToolbar appearance] setTintColor:[UIColor greenColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor greenColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor greenColor]];
    }
    else if([color isEqualToString:NSLocalizedString(@"Magenta", @"")])
    {
        [[UINavigationBar appearance] setTintColor:[UIColor magentaColor]];
        [self.navigationController.navigationBar setTintColor:[UIColor magentaColor]];
        [self.tabBarController.tabBar setTintColor:[UIColor magentaColor]];
        [[UIToolbar appearance] setTintColor:[UIColor magentaColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor magentaColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor magentaColor]];
    }
    else if([color isEqualToString:NSLocalizedString(@"Yellow", @"")])
    {
        [[UINavigationBar appearance] setTintColor:[UIColor yellowColor]];
        [self.navigationController.navigationBar setTintColor:[UIColor yellowColor]];
        [self.tabBarController.tabBar setTintColor:[UIColor yellowColor]];
        [[UIToolbar appearance] setTintColor:[UIColor yellowColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor yellowColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor yellowColor]];
    }
    else
    {
        [[UINavigationBar appearance] setTintColor:[UIColor blueColor]];
        [self.tabBarController.tabBar setTintColor:[UIColor blueColor]];
        [self.navigationController.navigationBar setTintColor:[UIColor blueColor]];
        [[UIToolbar appearance] setTintColor:[UIColor blueColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor blueColor]];
        [[UISwitch appearance] setOnTintColor:[UIColor blueColor]];
    }
}

//method to change the language
- (void)updateLanguage:(NSString *)language
{
    if(language)
    {
        //check which language was selected and change it
        if([language isEqualToString:NSLocalizedString(@"German", @"")])
        {
            ZWayAppDelegate.sharedDelegate.profile.language = @"de";
            [NSBundle setLanguage:@"de"];
        }
        else if([language isEqualToString:NSLocalizedString(@"English", @"")])
        {
            ZWayAppDelegate.sharedDelegate.profile.language = @"en";
            [NSBundle setLanguage:@"en"];
        }
        else if([language isEqualToString:NSLocalizedString(@"Russian", @"")])
        {
            ZWayAppDelegate.sharedDelegate.profile.language = @"ru";
            [NSBundle setLanguage:@"ru"];
        }
        else if([language isEqualToString:NSLocalizedString(@"Chinese", @"")])
        {
            ZWayAppDelegate.sharedDelegate.profile.language = @"zh-Hans";
            [NSBundle setLanguage:@"zh-Hans"];
        }
    }
    
    //update the picker arrays according to the localization
    colors = [NSArray arrayWithObjects:NSLocalizedString(@"Red", @"Red"), NSLocalizedString(@"Blue", @"Blue"), NSLocalizedString(@"Orange", @"Orange"), NSLocalizedString(@"Purple", @"Purple"), NSLocalizedString(@"Brown", @""), NSLocalizedString(@"Cyan", @""), NSLocalizedString(@"Green", @""), NSLocalizedString(@"Magenta", @""), NSLocalizedString(@"Yellow", @""), nil];
    
    languages = [NSArray arrayWithObjects:NSLocalizedString(@"German", @"German"), NSLocalizedString(@"English", @"English"), NSLocalizedString(@"Russian", @"Russian"), NSLocalizedString(@"Chinese", @"Chinese"), nil];
    
    //set the tab bar items to the current language
    [[self.tabBarController.tabBar.items objectAtIndex:0] setTitle:NSLocalizedString(@"Dashboard", @"")];
    [[self.tabBarController.tabBar.items objectAtIndex:1] setTitle:NSLocalizedString(@"Widgets", @"")];
    [[self.tabBarController.tabBar.items objectAtIndex:2] setTitle:NSLocalizedString(@"Notifications", @"")];
    [[self.tabBarController.tabBar.items objectAtIndex:3] setTitle:NSLocalizedString(@"Options", @"")];
    
    //set the title to the current language
    [self setTitle:NSLocalizedString(@"Options", @"")];
}

- (NSString*)languageTitle
{
    //check which language is selected
    if([_profile.language isEqualToString:@"en"])
        return NSLocalizedString(@"English", @"");
    else if([_profile.language isEqualToString:@"de"])
        return NSLocalizedString(@"German", @"");
    else if([_profile.language isEqualToString:@"ru"])
        return NSLocalizedString(@"Russian", @"");
    else if([_profile.language isEqualToString:@"zh-Hans"])
        return NSLocalizedString(@"Chinese", @"");
    else
        return NSLocalizedString(@"English", @"");
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

//number ob elements in the picker view
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    //depending on language or color
    if(languageSelecting == NO)
        return colors.count;
    else
        return languages.count;
}


//titles for picker view rows
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if(languageSelecting == NO)
        return [colors objectAtIndex:row];
    else
        return [languages objectAtIndex:row];
}

//selction of a row in the picker
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    //if it wasn´t a language change the color theme to selected color
    if(languageSelecting == NO)
    {
        _profile.theme = [colors objectAtIndex:row];
        ZWayAppDelegate.sharedDelegate.profile.theme = [colors objectAtIndex:row];
        [ZWayAppDelegate.sharedDelegate useColorTheme:ZWayAppDelegate.sharedDelegate.profile.theme];
        [self updateColor: ZWayAppDelegate.sharedDelegate.profile.theme];
    }
    //else update the language
    else
    {
        _profile.language = [languages objectAtIndex:row];
        [self updateLanguage:[languages objectAtIndex:row]];
    }
    
    //and hide the picker view
    [self hidePickerView];
    [tableview reloadData];
}


//save profile
- (void)store
{
    if (ZWayAppDelegate.sharedDelegate.settingsLocked) return;
    
    [ZWDataStore.store.managedObjectContext processPendingChanges];
    [ZWDataStore.store saveContext];
    
    if (_profile == ZWayAppDelegate.sharedDelegate.profile)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ZWProfileHasChanged" object:nil];
    }

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Profiles", @"") message:NSLocalizedString(@"Stored", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
    [alert show];
}

//delete the current profile
- (void)deleteProfile
{
    CMProfile *selectedProfile = ZWayAppDelegate.sharedDelegate.profile;
    
    ZWDataStore *store = ZWDataStore.store;
    
    [store.managedObjectContext deleteObject:_profile];
    [store.managedObjectContext processPendingChanges];
    
    if (selectedProfile == _profile)
        // deleted selected profile
        ZWayAppDelegate.sharedDelegate.profile = nil;
    
    //go back to superview
    [self.navigationController popViewControllerAnimated:YES];
}

//save old IP for later
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    oldIP = textField.text;
    return !ZWayAppDelegate.sharedDelegate.settingsLocked;
}

//what to do when a field was edited
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    //save each text field
    for(int i=10; i<14; i++)
    {
        //get the cell with it´s label and textfield
        UITableViewCell *cell = (UITableViewCell*)[tableview viewWithTag:i];
        UILabel *label = (UILabel*)[cell viewWithTag:1];
        UITextField *cellTextField = (UITextField*)[cell viewWithTag:2];
        NSString *text = textField.text;
        
        //check if it´s the IP field
        if([textField.text rangeOfString:@"192."].location != NSNotFound)
        {
            //remove http:// prefix
            if([text hasPrefix:@"http://"])
                text = [text substringFromIndex:[@"http://" length]];
            
            //add port if not added manually
            if (![text hasSuffix:@":8083"])
                text = [NSString stringWithFormat:@"%@:8083", text];
            
            //test connection with corrected IP
            [self testConnection:label.text With:text];
            
            if(i == 11)
            {
                //save IP to profile
                [_profile setValue:text forKey:[self conformToProfile:label.text]];
            
                //check if new IP differs from old one
                [cellTextField setText:text];
                if(![text isEqual:oldIP])
                {
                    //if yes reset dashboard
                    _profile.objects = nil;
                    _profile.changedIP = [NSNumber numberWithBool:YES];
                }
            }
        }
        //save textfield to profile
        else
        {
            [_profile setValue:cellTextField.text forKey:[self conformToProfile:label.text]];
        }
    }
}

//remove keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self keyboardWillHide];
    return YES;
}

//save values in specific profile field
- (NSString*)conformToProfile:(NSString*)profile
{
    if([profile isEqualToString:NSLocalizedString(@"Name", @"")])
        return @"name";
    else if([profile isEqualToString:NSLocalizedString(@"Home", @"")])
        return @"indoorUrl";
    else if([profile isEqualToString:NSLocalizedString(@"Login", @"")])
        return @"userLogin";
    else
        return @"userPassword";
}

@end
