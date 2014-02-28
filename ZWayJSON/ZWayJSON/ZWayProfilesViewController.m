//
//  ZWayProfilesViewController.m
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/21/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import "ZWayProfilesViewController.h"
#import "ZWayNewProfileViewController.h"
#import "CMProfile.h"
#import "ZWDataStore.h"
#import "ZWayAppDelegate.h"

@interface ZWayProfilesViewController ()

@end

@implementation ZWayProfilesViewController

@synthesize tableview;
@synthesize fetchController = _fetchController;
@synthesize editing;
@synthesize colorPicker;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    colors = [NSMutableArray new];
    [colors addObject:NSLocalizedString(@"Red", @"Red")];
    [colors addObject:NSLocalizedString(@"Blue", @"Blue")];
    [colors addObject:NSLocalizedString(@"Orange", @"Orange")];
    [colors addObject:NSLocalizedString(@"Purple", @"Purple")];
    [colors addObject:NSLocalizedString(@"Cyan", @"Cyan")];
    
    ZWDataStore *store = [ZWayAppDelegate sharedDelegate].dataStore;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Profile"];
    [request setIncludesPendingChanges:YES];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    
    self.fetchController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:store.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addProfile:)];
    addButton.enabled = !ZWayAppDelegate.sharedDelegate.settingsLocked;
    self.navigationItem.leftBarButtonItem = addButton;
    
    self.navigationItem.title = NSLocalizedString(@"Options", @"");
    
    colorPicker = [[UIPickerView alloc] initWithFrame:(CGRect){{0, 0}, 320, 480}];
    colorPicker.delegate = self;
    colorPicker.dataSource = self;
    colorPicker.showsSelectionIndicator = YES;
    colorPicker.center = (CGPoint){160, 640};
    colorPicker.hidden = YES;
    [self.view addSubview:colorPicker];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self reloadView];
    [tableview reloadData];
    editing = @"YES";
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)reloadView
{
    NSError *err = nil;
    if ([self.fetchController performFetch:&err])
    {
        NSIndexPath *path = [self.fetchController indexPathForObject:ZWayAppDelegate.sharedDelegate.profile];
        [self.tableview selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)addProfile:(id)sender
{
    if (ZWayAppDelegate.sharedDelegate.settingsLocked) return;
    editing = nil;
    [self performSegueWithIdentifier:@"pushProfileNew" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"pushProfileNew"])
    {
        ZWayNewProfileViewController *destination = segue.destinationViewController;
        destination.editing = editing;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _fetchController.sections.count + 1;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return NSLocalizedString(@"Profiles", @"");
            break;
            
        case 1:
            return NSLocalizedString(@"Color", @"color theme");
            break;
            
        default:
            return @"";
            break;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
        {
            id<NSFetchedResultsSectionInfo> sectInfo = [_fetchController.sections objectAtIndex:section];
            return sectInfo.numberOfObjects;
        }
            break;
            
        case 1:
            return 1;
            break;
            
        default:
            return 1;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    switch (indexPath.section) {
        case 0:
        {
            CMProfile *profile = [_fetchController objectAtIndexPath:indexPath];
            
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.textLabel.text = profile.name;
            if([ZWayAppDelegate.sharedDelegate.profile isEqual:profile])
            {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                
            }
            else
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
            break;
            
        case 1:
        {
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            if(ZWayAppDelegate.sharedDelegate.profile.theme != nil)
                cell.textLabel.text = ZWayAppDelegate.sharedDelegate.profile.theme;
            else
                cell.textLabel.text = NSLocalizedString(@"Default", @"default color");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
            
        default:
            break;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return !ZWayAppDelegate.sharedDelegate.settingsLocked;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0)
    {
        if (editingStyle == UITableViewCellEditingStyleDelete)
        {
            CMProfile *selectedProfile = ZWayAppDelegate.sharedDelegate.profile;
            CMProfile *profile = [_fetchController objectAtIndexPath:indexPath];
        
            ZWDataStore *store = ZWDataStore.store;
        
            [store.managedObjectContext deleteObject:profile];
            [store.managedObjectContext processPendingChanges];
        
            if (selectedProfile == profile)
            {
                // deleted selected profile
                ZWayAppDelegate.sharedDelegate.profile = nil;
            }
        
            NSError *err = nil;
            if ([self.fetchController performFetch:&err])
            {
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch(indexPath.section)
    {
        case 0:
        {
            CMProfile *profile = [_fetchController objectAtIndexPath:indexPath];
            ZWayAppDelegate.sharedDelegate.profile = profile;
    
            if ([tableview cellForRowAtIndexPath:indexPath].accessoryType == UITableViewCellAccessoryCheckmark)
                [self performSegueWithIdentifier:@"pushProfileNew" sender:self];
    
            [tableview cellForRowAtIndexPath:indexPath].selected = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ZWProfileHasChanged" object:nil];
            [ZWayAppDelegate.sharedDelegate useColorTheme:ZWayAppDelegate.sharedDelegate.profile.theme];
            [self updateColor:ZWayAppDelegate.sharedDelegate.profile.theme];
            [tableview reloadData];
        }
            break;
            
        case 1:
            if(indexPath.row == 0)
            {
                [self.tableview reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:YES];
                [self bringUpPickerViewWithRow:indexPath];
            }
            break;
    }
}

- (void)bringUpPickerViewWithRow:(NSIndexPath *)indexPath
{
    UITableViewCell *currentCellSelected = [self.tableview cellForRowAtIndexPath:indexPath];
    self.tableview.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableview setNeedsDisplay];
    [UIView animateWithDuration:1.0f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         self.colorPicker.hidden = NO;
         self.colorPicker.center = (CGPoint){currentCellSelected.frame.size.width/2, self.tableview.frame.origin.y + currentCellSelected.frame.size.height*4};
     }
                     completion:nil];
}

- (void)hidePickerView
{
    [UIView animateWithDuration:1.0f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         colorPicker.center = (CGPoint){160, 800};
     }
                     completion:^(BOOL finished)
     {
         colorPicker.hidden = YES;
     }];
    self.tableview.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.tableview setNeedsDisplay];
}

- (void)updateColor:(NSString*)color
{
    if([color isEqualToString:NSLocalizedString(@"Red", @"")])
    {
        [self.navigationController.navigationBar setTintColor:[UIColor redColor]];
        [[UIToolbar appearance] setTintColor:[UIColor redColor]];
        [[UINavigationBar appearance] setTintColor:[UIColor redColor]];
    }
    else if([color isEqualToString:NSLocalizedString(@"Blue", @"")])
    {
        [self.navigationController.navigationBar setTintColor:[UIColor blueColor]];
        [[UIToolbar appearance] setTintColor:[UIColor blueColor]];
        [[UINavigationBar appearance] setTintColor:[UIColor blueColor]];
    }
    else if([color isEqualToString:NSLocalizedString(@"Orange", @"")])
    {
        [self.navigationController.navigationBar setTintColor:[UIColor orangeColor]];
        [[UIToolbar appearance] setTintColor:[UIColor orangeColor]];
        [[UINavigationBar appearance] setTintColor:[UIColor orangeColor]];
    }
    else if([color isEqualToString:NSLocalizedString(@"Purple", @"")])
    {
        [self.navigationController.navigationBar setTintColor:[UIColor purpleColor]];
        [[UIToolbar appearance] setTintColor:[UIColor purpleColor]];
        [[UINavigationBar appearance] setTintColor:[UIColor purpleColor]];
    }
    else if([color isEqualToString:NSLocalizedString(@"Cyan", @"")])
    {
        [self.navigationController.navigationBar setTintColor:[UIColor cyanColor]];
        [[UIToolbar appearance] setTintColor:[UIColor cyanColor]];
        [[UINavigationBar appearance] setTintColor:[UIColor cyanColor]];
    }
    else
    {
        [self.navigationController.navigationBar setTintColor:[UIColor cyanColor]];
        [[UIToolbar appearance] setTintColor:[UIColor cyanColor]];
        [[UINavigationBar appearance] setTintColor:[UIColor cyanColor]];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableview cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return colors.count;
}

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [colors objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    ZWayAppDelegate.sharedDelegate.profile.theme = [colors objectAtIndex:row];
    [ZWayAppDelegate.sharedDelegate useColorTheme:ZWayAppDelegate.sharedDelegate.profile.theme];
    [self updateColor: ZWayAppDelegate.sharedDelegate.profile.theme];
    [self hidePickerView];
    [tableview reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    ZWDataStore *store = ZWDataStore.store;
     
     if (!ZWayAppDelegate.sharedDelegate.settingsLocked)
     {
     [store saveContext];
     }
     
     if (store.getProfilesCount == 0)
     {
     // do not dismiss profiles screen if there's no profile
     
     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Profiles", @"") message:NSLocalizedString(@"NoProfile", @"Message that a profile should be created") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
     [alert show];
     
     return;
     }
     
     CMProfile *selectedProfile = ZWayAppDelegate.sharedDelegate.profile;
     if (selectedProfile == nil || selectedProfile.isDeleted)
     {
     // do not dismiss profiles screen if no profile is selected
     
     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Profiles", @"") message:NSLocalizedString(@"NoSelection", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
     [alert show];
     
     return;
     }
     
     NSURL *plistPath = [[store applicationDocumentsDirectory] URLByAppendingPathComponent:@"settings.plist"];
     
     NSMutableDictionary *dict = [NSMutableDictionary dictionary];
     [dict setValue:selectedProfile.name forKey:@"profile"];
     [dict setValue:[NSNumber numberWithBool:ZWayAppDelegate.sharedDelegate.settingsLocked] forKey:@"settingsLocked"];
     
     [[NSArray arrayWithObject:dict] writeToURL:plistPath atomically:YES];
}

@end
