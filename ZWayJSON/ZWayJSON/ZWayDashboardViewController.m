//
//  ZWayFirstViewController.m
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/15/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import "ZWayDashboardViewController.h"
#import "ZWDevice.h"
#import "ZWDeviceItem.h"
#import "ZWDataHandler.h"
#import "ZWayAppDelegate.h"


@class ZWDevice;

@interface ZWayDashboardViewController ()

@end

@implementation ZWayDashboardViewController
@synthesize noItemsLabel;
@synthesize tableview;


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (ZWayAppDelegate.sharedDelegate.profile != nil)
    {
        //get Objects for profile
        objects = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:ZWayAppDelegate.sharedDelegate.profile.objects]];
    
        if(objects.count != 0)
        {
            tableview.hidden = NO;
            noItemsLabel.hidden = YES;
            self.navigationItem.rightBarButtonItem = self.editButtonItem;
            self.navigationItem.rightBarButtonItem.style = UIBarButtonItemStylePlain;
        }
        else
        {
            tableview.hidden = YES;
            noItemsLabel.hidden = NO;
            self.navigationItem.rightBarButtonItem = nil;
        }
        [tableview reloadData];
    }
    else
    {
        tableview.hidden = YES;
        noItemsLabel.hidden = NO;
    }
    
    noItemsLabel.text = NSLocalizedString(@"NoDashboard", @"");
    [tableview reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self registerCells];
}

- (void)registerCells
{
    [self.tableview registerNib:[UINib nibWithNibName:@"ZWDeviceItemBattery" bundle:nil] forCellReuseIdentifier:@"battery"];
    [self.tableview registerNib:[UINib nibWithNibName:@"ZWDeviceItemBlinds" bundle:nil] forCellReuseIdentifier:@"Blinds"];
    [self.tableview registerNib:[UINib nibWithNibName:@"ZWDeviceItemDimmer" bundle:nil] forCellReuseIdentifier:@"probe"];
    [self.tableview registerNib:[UINib nibWithNibName:@"ZWDeviceItemMeter" bundle:nil] forCellReuseIdentifier:@"Meter"];
    [self.tableview registerNib:[UINib nibWithNibName:@"ZWDeviceItemSensorBinary" bundle:nil] forCellReuseIdentifier:@"fan"];
    [self.tableview registerNib:[UINib nibWithNibName:@"ZWDeviceItemSensorMulti" bundle:nil] forCellReuseIdentifier:@"switchMultilevel"];
    [self.tableview registerNib:[UINib nibWithNibName:@"ZWDeviceItemSwitch" bundle:nil] forCellReuseIdentifier:@"switchBinary"];
    [self.tableview registerNib:[UINib nibWithNibName:@"ZWDeviceItemThermostat" bundle:nil] forCellReuseIdentifier:@"thermostat"];
}

#pragma mark: Cell definition

//enable editing of rows
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

//Set rows in tabeview to count of objects
- (NSInteger)tableView:tableView numberOfRowsInSection:(NSInteger)section
{
    return objects.count;
}


//set height for cells
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(objects.count != 0)
    {
        ZWDevice *device = [objects objectAtIndex:indexPath.row];
        return [device height];
    }
    return 60;
}


//display the devives
- (ZWDeviceItem *)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(objects.count != 0)
    {
        ZWDevice *device = [objects objectAtIndex:indexPath.row];
        ZWDeviceItem *cell = [device createUIforTableView:tableView atPos:indexPath];
        cell.device = device;
        [cell setDisplayName];
        [cell updateState];
        
        ZWDeviceItem __weak *weakCell = cell;
        
        [weakCell setAppearanceWithBlock:^{
            weakCell.containingTableView = tableView;
            [weakCell setCellHeight:weakCell.frame.size.height];
            
            NSMutableArray *rightUtilityButtons = [NSMutableArray new];
            
            [rightUtilityButtons sw_addUtilityButtonWithColor:
             [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                        title:NSLocalizedString(@"Remove", @"Remove Button")];
            weakCell.rightUtilityButtons = rightUtilityButtons;
            weakCell.delegate = self;
        } force:NO];
        
        weakCell.showsReorderControl = YES;
        [cell hideControls:editMode];
        return cell;
    }
    else
    {
        noItemsLabel.hidden = NO;
        tableview.hidden = YES;
        ZWDeviceItem *cell = [[ZWDeviceItem alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        return cell;
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
        {
            NSIndexPath *cellIndexPath = [tableview indexPathForCell:cell];
            if(objects.count -1 != 0)
            {
                [objects removeObjectAtIndex:cellIndexPath.row];
                [tableview deleteRowsAtIndexPaths:[NSArray arrayWithObject:cellIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
            else
            {
                tableview.hidden = YES;
                noItemsLabel.hidden = NO;
                [objects removeObjectAtIndex:cellIndexPath.row];
            }
        }
            break;
            
        default:
            break;
    }
}


-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.editing)
        return UITableViewCellEditingStyleDelete;
    else
        return UITableViewCellEditingStyleNone;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.tableview setEditing:editing animated:animated];
    editMode = editing;
    [self.tableview performSelector:@selector(reloadData) withObject:nil afterDelay:0.3];
}



// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}


// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    ZWDevice *deviceA = [objects objectAtIndex:fromIndexPath.row];
    [objects removeObjectAtIndex:fromIndexPath.row];
    [objects insertObject:deviceA atIndex:toIndexPath.row];
}


//what to do when editing
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if(objects.count -1 != 0)
        {
            [objects removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        else
        {
            tableview.hidden = YES;
            noItemsLabel.hidden = NO;
            [objects removeObjectAtIndex:indexPath.row];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSData *objectData = [NSKeyedArchiver archivedDataWithRootObject:objects];
    ZWayAppDelegate.sharedDelegate.profile.objects = objectData;
}

@end
