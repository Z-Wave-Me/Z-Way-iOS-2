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


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.tabBarController.tabBar setTranslucent:NO];
    
    ZWDataStore *store = ZWDataStore.store;
    
    self.navigationController.navigationBar.translucent = NO;
    
    //decide if profile is new or editing
    if(![editing isEqualToString:@"YES"])
    {
        //create a new profile
        NSEntityDescription *profileEntity = [NSEntityDescription entityForName:@"Profile" inManagedObjectContext:store.managedObjectContext];
        
        CMProfile *profile = [[CMProfile alloc] initWithEntity:profileEntity insertIntoManagedObjectContext:store.managedObjectContext];
        //set default name and outdoor URL
        profile.name = @"Name";
        profile.language = @"en";
        [store saveContext];
        self.navigationItem.title =  NSLocalizedString(@"NewProfile", @"New Profile title");
        _profile = profile;
    }
    else
    {
        //load profile info when editing
        _profile = ZWayAppDelegate.sharedDelegate.profile;
        self.navigationItem.title = _profile.name;
    }
    
    //decide the order of cells
    _fields = [NSMutableDictionary dictionary];
    [_fields setObject:[[[NSBundle mainBundle] loadNibNamed:@"ZWTextEditCell" owner:self options:nil] objectAtIndex:0] forKey:@"name"];
    [_fields setObject:[[[NSBundle mainBundle] loadNibNamed:@"ZWUrlEditCell" owner:self options:nil] objectAtIndex:0] forKey:@"indoorUrl"];
    [_fields setObject:[[[NSBundle mainBundle] loadNibNamed:@"ZWTextEditCell" owner:self options:nil] objectAtIndex:0] forKey:@"userLogin"];
    [_fields setObject:[[[NSBundle mainBundle] loadNibNamed:@"ZWPasswordCell" owner:self options:nil] objectAtIndex:0] forKey:@"userPassword"];
    
    _fieldsOrder = [NSMutableArray arrayWithObjects:@"name", @"indoorUrl", @"userLogin", @"userPassword", nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// Checks if we have a connection or not
- (void)testConnection:(NSString*)field With:(UITextField*)connection
{
    //get current cell
    UITableViewCell *cell = (UITableViewCell*)[tableview viewWithTag:connection.tag];
    
    //check if it´s the IP field
    if([field isEqualToString:NSLocalizedString(@"Home", @"")])
    {
        //set up the images for valid or invalid IP
        UIImageView *connected = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"connected-g.png"]];
        UIImageView *fail = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"wrong.png"]];
        
        //create connection with given IP to see if it works
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", connection.text]];
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:3.0];
        NSError *error;
        NSURLResponse *response;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if(!data)
            connection = nil;
        
        //check the response
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        int responseStatusCode = [httpResponse statusCode];
        
        //set the fail image for invalid IP
        if(responseStatusCode != 200)
        {
            cell.accessoryView = fail;
        }
        //or the valid image for the valid IP
        else
        {
            cell.accessoryView = connected;
        }
    }
}

//dismiss keyboard when leaving the view
- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
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
- (void)keyboardWillHide:(NSNotification *)notification
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

//3 sections in tableview
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

//title for sections
- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return nil;
        case 1:
            return NSLocalizedString(@"IndoorServer", @"");
        case 2:
            return NSLocalizedString(@"RemoteAccess", @"");
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
    
    /*UIButton *checkButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [checkButton setFrame:CGRectMake(0, 100, 280, 25)];
    checkButton.backgroundColor = [UIColor clearColor];
    [checkButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [checkButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [checkButton addTarget:self action:@selector(chkBtnHandler:) forControlEvents:UIControlEventTouchUpInside];
    if([ZWayAppDelegate.sharedDelegate.profile.useSpeech boolValue] == YES)
        [checkButton setSelected:YES];
    checkButton.hidden = YES;
    
    [checkButton setImage:nil forState:UIControlStateNormal];
    [checkButton setImage:[UIImage imageNamed:@"connected-g.png"] forState:UIControlStateSelected];
    
    [checkButton setTitle:NSLocalizedString(@"Speech", @"Option to activate speach recognition")
            forState:UIControlStateNormal];
    [checkButton setTitle:NSLocalizedString(@"Speech", @"")
            forState:UIControlStateSelected];*/
    
    //set titles for rows
    switch (indexPath.section)
    {
        case 0:
            name = @"name";
            displayName = NSLocalizedString(@"Name", @"");
            break;
            
        case 1:
            name = @"indoorUrl";
            displayName = NSLocalizedString(@"Home", @"At home");
            break;
            
        case 2:
        {
            switch (indexPath.row)
            {
                case 0:
                    name = @"userLogin";
                    displayName = NSLocalizedString(@"Login", @"");
                    break;
                case 1:
                    name = @"userPassword";
                    displayName = NSLocalizedString(@"Password", @"");
                    break;
            }
            break;
        }
    }
    
    //place buttons on bottom
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(20, 0, 280, 200)];
    [footerView addSubview:saveButton];
    [footerView addSubview:deleteButton];
    //[footerView addSubview:checkButton];
    tableView.tableFooterView = footerView;
    
    cell = [_fields objectForKey:name];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    //decide if the profile is new or loaded for naming
    if(![loaded isEqualToString:@"YES"])
    {
        label = (UILabel*)[cell viewWithTag:1];
        editor = (UITextField*)[cell viewWithTag:2];
    }
    else
    {
        editor = (UITextField*)[cell viewWithTag:cell.tag];
        label = (UILabel*)[cell viewWithTag:(cell.tag + 1)];
    }
    
    if([name isEqualToString:@"userPassword"])
        loaded = @"YES";
    
    //set the text
    label.text = displayName;
    editor.text = [_profile valueForKey:name];
    editor.tag = (indexPath.section * 1000 + indexPath.row + 1);
    cell.tag = editor.tag;
    label.tag = (editor.tag +1);
    
    return cell;
}

/*- (void)chkBtnHandler:(id)sender {
    [(UIButton *)sender setSelected:![(UIButton *)sender isSelected]];
    
    if([(UIButton *)sender isSelected])
        _profile.useSpeech = [NSNumber numberWithBool:YES];
    else
        _profile.useSpeech = [NSNumber numberWithBool:NO];
}*/

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

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Profiles" message:NSLocalizedString(@"Stored", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
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


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *name = nil;
    
    switch (indexPath.section)
    {
        case 0:
            name = @"name";
            break;
        case 1:
        {
            switch (indexPath.row)
            {
                case 0:
                    name = @"indoorUrl";
                    break;
            }
            break;
        }
            
        case 2:
        {
            switch (indexPath.row)
            {
                case 0:
                    name = @"userLogin";
                    break;
                case 1:
                    name = @"userPassword";
                    break;
            }
            break;
        }
            
        case 3:
        {
            if (indexPath.row == 0) {
                
            }
        }
    }
    
    //scroll to selected row
    UITableViewCell* cell = [_fields objectForKey:name];
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    
    //start editing selected row
    UITextField *editor = (UITextField*)[cell viewWithTag:cell.tag];
    [editor becomeFirstResponder];
}

//save old IP for later
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    oldIP = textField.text;
    return !ZWayAppDelegate.sharedDelegate.settingsLocked;
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    //endend the editing
    UITableViewCell *cell = (UITableViewCell*)[tableview viewWithTag:textField.tag];
    UILabel *label = (UILabel*)[cell viewWithTag:(textField.tag + 1)];
    [self testConnection:label.text With:textField];
    [_profile setValue:textField.text forKey:[self conformToProfile:label.text]];
    
    //reset the dashboard when the IP changed
    if([label.text isEqualToString:NSLocalizedString(@"Home", @"")])
    {
        if(![textField.text isEqual:oldIP])
            ZWayAppDelegate.sharedDelegate.profile.objects = nil;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

//save values in profile
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