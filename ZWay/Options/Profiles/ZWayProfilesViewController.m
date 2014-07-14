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
#import "ZWayLanguage.h"
#import "ZWayAppDelegate.h"

@interface ZWayProfilesViewController ()

@end

@implementation ZWayProfilesViewController

@synthesize tableview;
@synthesize fetchController = _fetchController;
@synthesize editing;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setOpaque:YES];
    [self.tabBarController.tabBar setTranslucent:NO];
    
    //get the profiles
    ZWDataStore *store = [ZWayAppDelegate sharedDelegate].dataStore;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Profile"];
    [request setIncludesPendingChanges:YES];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    
    self.fetchController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:store.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    
    //add button to add profiles
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addProfile:)];
    addButton.enabled = !ZWayAppDelegate.sharedDelegate.settingsLocked;
    self.navigationItem.rightBarButtonItem = addButton;
    
    self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
    
    self.navigationItem.title = NSLocalizedString(@"Options", @"");
}

- (void)viewWillAppear:(BOOL)animated
{
    [self reloadView];
    [tableview reloadData];
    [self setTitle:NSLocalizedString(@"Options", @"")];
    editing = @"YES";
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortrait);
}

//reload tableview so all profiles are displayed
- (void)reloadView
{
    NSError *err = nil;
    if ([self.fetchController performFetch:&err])
    {
        NSIndexPath *path = [self.fetchController indexPathForObject:ZWayAppDelegate.sharedDelegate.profile];
        [self.tableview selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

//method to add a profile
- (void)addProfile:(id)sender
{
    if (ZWayAppDelegate.sharedDelegate.settingsLocked) return;
    editing = nil;
    
    //call new profile screen
    [self performSegueWithIdentifier:@"pushProfileNew" sender:self];
}

//provide information if new profile or editing current profile
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"pushProfileNew"])
    {
        ZWayNewProfileViewController *destination = segue.destinationViewController;
        destination.editing = editing;
    }
}

//+2 sections because of the color and language picker
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _fetchController.sections.count;
}

//set section titles
- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
        {
            id<NSFetchedResultsSectionInfo> sectInfo = [_fetchController.sections objectAtIndex:section];
            if(sectInfo.numberOfObjects == 0)
            {
                return NSLocalizedString(@"NoProfile", @"");
            }
            return NSLocalizedString(@"Profiles", @"");
        }
            break;
            
        default:
            return @"";
            break;
    }
}

//only the profile count can vary all other have 1 row per section
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
        {
            id<NSFetchedResultsSectionInfo> sectInfo = [_fetchController.sections objectAtIndex:section];
            return sectInfo.numberOfObjects;
        }
            break;
            
        default:
            return 1;
            break;
    }
}

//display profile cells and language/color
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    switch (indexPath.section) {
            
        //display profiles in section 0
        case 0:
        {
            CMProfile *profile = [_fetchController objectAtIndexPath:indexPath];
            
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.textLabel.text = profile.name;
            
            //check if it´s the currently selected profile
            if([ZWayAppDelegate.sharedDelegate.profile isEqual:profile])
            {
                //mark it as selected
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                
            }
            //mark it as normal
            else
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
            break;
         
        default:
            break;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return !ZWayAppDelegate.sharedDelegate.settingsLocked;
}

//method to delete profiles
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //has to be in profile section
    if(indexPath.section == 0)
    {
        if (editingStyle == UITableViewCellEditingStyleDelete)
        {
            //deleting the selected profile
            CMProfile *selectedProfile = ZWayAppDelegate.sharedDelegate.profile;
            CMProfile *profile = [_fetchController objectAtIndexPath:indexPath];
        
            ZWDataStore *store = ZWDataStore.store;
        
            [store.managedObjectContext deleteObject:profile];
            [store.managedObjectContext processPendingChanges];
        
            //set the selected profile nil, because we deleted it
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

//all cells have the same height
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
            //check if the tapped profile is the selected profile
            CMProfile *profile = [_fetchController objectAtIndexPath:indexPath];
            ZWayAppDelegate.sharedDelegate.profile = profile;
    
            //go into editing view if it was
            if ([tableview cellForRowAtIndexPath:indexPath].accessoryType == UITableViewCellAccessoryCheckmark)
                [self performSegueWithIdentifier:@"pushProfileNew" sender:self];
    
            //or else set the tapped profile as selected
            [tableview cellForRowAtIndexPath:indexPath].selected = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ZWProfileHasChanged" object:nil];
            
            //change color and language according to the newly selected profile
            [ZWayAppDelegate.sharedDelegate useColorTheme:ZWayAppDelegate.sharedDelegate.profile.theme];
            [self updateLanguage:ZWayAppDelegate.sharedDelegate.profile.language];
            [self updateColor:ZWayAppDelegate.sharedDelegate.profile.theme];
            [tableview reloadData];
        }
            break;
    }
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
        [NSBundle setLanguage:language];
    }
    
    //set the tab bar items to the current language
    [[self.tabBarController.tabBar.items objectAtIndex:0] setTitle:NSLocalizedString(@"Dashboard", @"")];
    [[self.tabBarController.tabBar.items objectAtIndex:1] setTitle:NSLocalizedString(@"Widgets", @"")];
    [[self.tabBarController.tabBar.items objectAtIndex:2] setTitle:NSLocalizedString(@"Notifications", @"")];
    [[self.tabBarController.tabBar.items objectAtIndex:3] setTitle:NSLocalizedString(@"Options", @"")];
    
    //set the title to the current language
    [self setTitle:NSLocalizedString(@"Options", @"")];
}

//mark selected row
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableview cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

//save profiles when view disappears
- (void)viewWillDisappear:(BOOL)animated
{
    ZWDataStore *store = ZWDataStore.store;
     
     if (!ZWayAppDelegate.sharedDelegate.settingsLocked)
     {
     [store saveContext];
     }
     
     CMProfile *selectedProfile = ZWayAppDelegate.sharedDelegate.profile;
     
     NSURL *plistPath = [[store applicationDocumentsDirectory] URLByAppendingPathComponent:@"settings.plist"];
     
     NSMutableDictionary *dict = [NSMutableDictionary dictionary];
     [dict setValue:selectedProfile.name forKey:@"profile"];
     [dict setValue:[NSNumber numberWithBool:ZWayAppDelegate.sharedDelegate.settingsLocked] forKey:@"settingsLocked"];
     
     [[NSArray arrayWithObject:dict] writeToURL:plistPath atomically:YES];
}

@end
