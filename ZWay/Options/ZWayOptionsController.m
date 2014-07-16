//
//  ZWayOptionsController.m
//  ZWay
//
//  Created by Lucas von Hacht on 30/06/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import "ZWayOptionsController.h"

@interface ZWayOptionsController ()

@end

@implementation ZWayOptionsController

@synthesize tableview;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setOpaque:YES];
    [self.tabBarController.tabBar setTranslucent:NO];
    
    self.tableview.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = NSLocalizedString(@"Options", @"");
    
    [tableview reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortrait);
}

// 2 sections for Profiles and About
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

//set section titles
- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return NSLocalizedString(@"Profiles", @"");
            break;
            
        case 1:
            return NSLocalizedString(@"About", @"About");
            break;
            
        default:
            return @"";
            break;
    }
}

//always one row
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

//display profile cell and About
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    switch (indexPath.section) {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"Profiles", @"");
            break;
            
        case 1:
            cell.textLabel.text = NSLocalizedString(@"About", @"");
            break;
            
        default:
            break;
    }
    
    //no selection and indicator
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
            [self performSegueWithIdentifier:@"pushProfiles" sender:self];
            break;
            
        case 1:
            [self performSegueWithIdentifier:@"pushAbout" sender:self];
            break;
            
        default:
            break;
    }
}

@end
