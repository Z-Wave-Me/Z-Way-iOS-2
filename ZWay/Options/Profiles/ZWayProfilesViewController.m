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
    editing = @"YES";
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
            return NSLocalizedString(@"Profiles", @"");
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
            [self updateLanguage:nil];
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
        [self.navigationController.navigationBar setTintColor:[UIColor redColor]];
        [[UINavigationBar appearance] setTintColor:[UIColor redColor]];
        [self.tabBarController.tabBar setTintColor:[UIColor redColor]];
    }
    else if([color isEqualToString:NSLocalizedString(@"Blue", @"")])
    {
        [self.navigationController.navigationBar setTintColor:[UIColor blueColor]];
        [[UINavigationBar appearance] setTintColor:[UIColor blueColor]];
        [self.tabBarController.tabBar setTintColor:[UIColor blueColor]];
    }
    else if([color isEqualToString:NSLocalizedString(@"Orange", @"")])
    {
        [self.navigationController.navigationBar setTintColor:[UIColor orangeColor]];
        [[UINavigationBar appearance] setTintColor:[UIColor orangeColor]];
        [self.tabBarController.tabBar setTintColor:[UIColor orangeColor]];
    }
    else if([color isEqualToString:NSLocalizedString(@"Purple", @"")])
    {
        [self.navigationController.navigationBar setTintColor:[UIColor purpleColor]];
        [[UINavigationBar appearance] setTintColor:[UIColor purpleColor]];
        [self.tabBarController.tabBar setTintColor:[UIColor purpleColor]];
    }
    else
    {
        [self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
        [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];
        [self.tabBarController.tabBar setTintColor:[UIColor blackColor]];
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
            ZWayAppDelegate.sharedDelegate.profile.language = @"zh";
            [NSBundle setLanguage:@"zh"];
        }
    }
    else
    {
        [NSBundle setLanguage:ZWayAppDelegate.sharedDelegate.profile.language];
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
