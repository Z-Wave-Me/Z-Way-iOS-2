//
//  ZWayRoomsViewController.m
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/22/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import "ZWayRoomsViewController.h"
#import "ZWDevice.h"
#import "ZWDeviceItem.h"
#import "ZWayAppDelegate.h"
#import "SWTableViewCell.h"


@interface ZWayRoomsViewController ()

@end

@implementation ZWayRoomsViewController

@synthesize roomDevices;
@synthesize tagsDevices;
@synthesize typesDevices;
@synthesize selected;
@synthesize deviceIndex;
@synthesize displayDevices;
@synthesize tableview;
@synthesize noItemsLabel;

- (void)viewDidLoad
{
    objectsToDash = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:ZWayAppDelegate.sharedDelegate.profile.objects]];
    
    NSInteger index = [deviceIndex integerValue];
    
    if([selected isEqualToString:@"Rooms"] && roomDevices.count !=0)
        displayDevices = [[NSMutableArray alloc] initWithArray:[roomDevices objectAtIndex:index]];
    else if ([selected isEqualToString:@"Types"])
        displayDevices = [[NSMutableArray alloc] initWithArray:[typesDevices objectAtIndex:index]];
    else if ([selected isEqualToString:@"Tags"])
        displayDevices = [[NSMutableArray alloc] initWithArray:[tagsDevices objectAtIndex:index]];
    
    tableview.hidden = NO;
    noItemsLabel.hidden = YES;
    noItemsLabel.text = NSLocalizedString(@"NoDevices", @"");
    [tableview reloadData];
}

- (BOOL)moveToDash:(ZWDevice*)device
{
    BOOL isPart = NO;
    for(NSInteger i=0; i<objectsToDash.count; i++)
    {
        ZWDevice *dashObject = [objectsToDash objectAtIndex:i];
        if([dashObject.deviceId isEqualToString:device.deviceId])
        {
            isPart = YES;
        }
    }
    
    if(isPart == NO)
    {
        [objectsToDash addObject:device];
        return YES;
    }
    
    return NO;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(displayDevices.count == 0)
    {
        tableview.hidden = YES;
        noItemsLabel.hidden = NO;
    }
    
    return displayDevices.count;
}


//set height for cells
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(displayDevices.count != 0)
    {
        ZWDevice *device = [displayDevices objectAtIndex:indexPath.row];
        return [device height];
    }
    return 60;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(displayDevices.count != 0)
    {
    ZWDevice *device = [displayDevices objectAtIndex:indexPath.row];
    ZWDeviceItem *cell = [device createUIforTableView:tableView atPos:indexPath];
    cell.device = device;
    [cell setDisplayName];
    [cell updateState];
    
    ZWDeviceItem __weak *weakCell = cell;
    
    [weakCell setAppearanceWithBlock:^{
        weakCell.containingTableView = tableView;
        [weakCell setCellHeight:[self tableView:tableView heightForRowAtIndexPath:indexPath]];
        
        NSMutableArray *rightUtilityButtons = [NSMutableArray new];
        
        [rightUtilityButtons sw_addUtilityButtonWithColor:
         [UIColor lightGrayColor] title:NSLocalizedString(@"ToDash", @"Message: Move to dashboard")];
        weakCell.rightUtilityButtons = rightUtilityButtons;
        weakCell.delegate = self;
    } force:NO];
    
    weakCell.showsReorderControl = YES;
    
    return weakCell;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier"];
    return cell;
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
        {
            NSIndexPath *cellIndexPath = [tableview indexPathForCell:cell];
            ZWDevice *device = [displayDevices objectAtIndex:cellIndexPath.row];
            BOOL moved = [self moveToDash:device];

            if(moved == YES)
            {
                [[cell.rightUtilityButtons objectAtIndex:index] setTitle:NSLocalizedString(@"Done", @"Message that the object was added") forState:UIControlStateNormal];
                [self performSelector:@selector(changeToNormal:) withObject:cell afterDelay:3];
                [cell performSelector:@selector(hideUtilityButtonsAnimated:) withObject:[NSNumber numberWithBool:YES] afterDelay:3];
            }
            else
            {
                [[cell.rightUtilityButtons objectAtIndex:index] setTitle:NSLocalizedString(@"IsPart", @"Message that the device is already part of the dashboard") forState:UIControlStateNormal];
                [self performSelector:@selector(changeToNormal:) withObject:cell afterDelay:3];
                [cell performSelector:@selector(hideUtilityButtonsAnimated:) withObject:[NSNumber numberWithBool:YES] afterDelay:3];
            }
        }
            break;
            
        default:
            break;
    }
}

- (void)changeToNormal:(SWTableViewCell*)cell
{
    [[cell.rightUtilityButtons objectAtIndex:0] setTitle:NSLocalizedString(@"ToDash", @"") forState:UIControlStateNormal];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.editing)
        return UITableViewCellEditingStyleDelete;
    else
        return UITableViewCellEditingStyleNone;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSData *arrayData = [NSKeyedArchiver archivedDataWithRootObject:objectsToDash];
    ZWayAppDelegate.sharedDelegate.profile.objects = arrayData;
    [ZWDataStore.store.managedObjectContext processPendingChanges];
    [ZWDataStore.store saveContext];
}

@end
