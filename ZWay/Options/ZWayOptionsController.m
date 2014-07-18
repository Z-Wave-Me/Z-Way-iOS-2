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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // create the parent view that will hold header Label
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.frame.size.width, 22.0)];
    
    // create the label
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    
    headerLabel.frame = CGRectMake(15, customView.center.y, tableView.frame.size.width, 22.0);
    
    switch (section) {
        case 0:
            headerLabel.text = NSLocalizedString(@"Profiles", @"");
            break;
            
        case 1:
            headerLabel.text = NSLocalizedString(@"About", @"About");
            break;
    }

    [customView addSubview:headerLabel];
    
    return customView;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 35;
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
    [cell.textLabel setFont:[UIFont systemFontOfSize:20.0]];
    cell.textLabel.frame = CGRectMake(15, 0, cell.frame.size.width, cell.frame.size.height);
    
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
