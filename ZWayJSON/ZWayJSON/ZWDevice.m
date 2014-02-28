//
//  ZWDevice.m
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/16/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import "ZWDevice.h"
#import "ZWDataHandler.h"
#import "ZWDeviceItem.h"
#import "ZWDataHandler.h"
#import "ZWDeviceItemBattery.h"
#import "ZWDeviceItemFan.h"
#import "ZWDeviceItemSensorMulti.h"
#import "ZWDeviceItemSwitch.h"
#import "ZWDeviceItemThermostat.h"

@implementation ZWDevice

@synthesize deviceType = _deviceType;
@synthesize deviceId = _deviceId;
@synthesize location = _location;
@synthesize tags = _tags;
@synthesize metrics = _metrics;
@synthesize updateTime = _updateTime;

//set and update the devices
- (NSMutableArray*)updateObjects:(NSMutableArray*)array WithDict:(NSDictionary *)dict
{
    NSMutableArray *devices = [NSMutableArray new];
    
    if(array != nil)
    {
        for(NSInteger i=0; i<array.count; i++)
            {
                ZWDevice *device = [ZWDevice new];
                NSDictionary *dict = [array objectAtIndex:i];
                device.deviceType = [dict valueForKey:@"deviceType"];
                device.deviceId = [dict valueForKey:@"id"];
                device.location = [dict valueForKey:@"location"];
                device.metrics = [dict objectForKey:@"metrics"];
                device.tags = [dict objectForKey:@"tags"];
                device.updateTime = [dict valueForKey:@"updateTime"];
                [devices addObject:device];
            }
        return devices;
    }
    else
    {
        ZWDevice *device = [[ZWDevice alloc] init];
        device.deviceType = [dict valueForKey:@"deviceType"];
        device.deviceId = [dict valueForKey:@"id"];
        device.location = [dict valueForKey:@"location"];
        device.metrics = [dict objectForKey:@"metrics"];
        device.tags = [dict objectForKey:@"tags"];
        device.updateTime = [dict valueForKey:@"updateTime"];
        [devices addObject:device];
        
        return devices;
    }
    return devices;
}

//define the device type
- (NSString*)getDeviceType:(ZWDevice *)device
{
    return device.deviceType;
}

- (CGFloat)height
{
    if ([_deviceType isEqualToString:@"probe"] || [_deviceType isEqualToString:@"sensor"])
    {
        return 60;
    }
    else if ([_deviceType isEqualToString:@"switchBinary"])
    {
        return 60;
    }
    else if ([_deviceType isEqualToString:@"thermostat"] || [_deviceType isEqualToString:@"fan"])
    {
        return 90;
    }
    else if ([_deviceType isEqualToString:@"fan"] ||
             [_deviceType isEqualToString:@"switchMultilevel"])
    {
        return 60;
    }
    else if ([_deviceType isEqualToString:@"battery"])
    {
        return 60;
    }
    
    return 44;
}

- (ZWDeviceItem*)createUIforTableView:(UITableView *)tableView atPos:(NSIndexPath *)indexPath
{
    ZWDeviceItem *item = (ZWDeviceItem*)[tableView dequeueReusableCellWithIdentifier:_deviceType];

        if ([_deviceType isEqualToString:@"probe"] || [_deviceType isEqualToString:@"sensor"] || [_deviceType isEqualToString:@"battery"])
            item = [ZWDeviceItemBattery device];
        else if ([_deviceType isEqualToString:@"switchBinary"])
            item = [ZWDeviceItemSwitch device];
        else if ([_deviceType isEqualToString:@"switchMultilevel"])
            item = [ZWDeviceItemSensorMulti device];
        else if ([_deviceType isEqualToString:@"thermostat"])
            item = [ZWDeviceItemThermostat device];
        else if ([_deviceType isEqualToString:@"fan"])
            item = [ZWDeviceItemFan device];
        else
            item = [[ZWDeviceItem alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:_deviceType];

    return item;
}

//reload devices from archieve
- (id)initWithCoder:(NSCoder *)decoder
{
    if((self = [super init]))
    {
        self.deviceType = [decoder decodeObjectForKey:@"deviceType"];
        self.deviceId = [decoder decodeObjectForKey:@"deviceId"];
        self.location = [decoder decodeObjectForKey:@"location"];
        self.tags = [decoder decodeObjectForKey:@"tags"];
        self.metrics = [decoder decodeObjectForKey:@"metrics"];
        self.updateTime = [decoder decodeObjectForKey:@"updateTime"];
    }
    return self;
}

//Encode device objects for archieving
- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.deviceType forKey:@"deviceType"];
    [encoder encodeObject:self.deviceId forKey:@"deviceId"];
    [encoder encodeObject:self.location forKey:@"location"];
    [encoder encodeObject:self.tags forKey:@"tags"];
    [encoder encodeObject:self.metrics forKey:@"metrics"];
    [encoder encodeObject:self.updateTime forKey:@"updateTime"];
}


@end
