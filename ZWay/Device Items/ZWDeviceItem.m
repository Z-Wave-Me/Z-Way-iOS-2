//
//  ZWDeviceItem.m
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/20/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import "ZWDeviceItem.h"
#import "ZWDevice.h"

@implementation ZWDeviceItem

@synthesize nameView = _nameView;
@synthesize device = _device;
@synthesize authent;

- (void)setDisplayName
{
    //extract the device type
    NSDictionary *dict = self.device.metrics;
    self.nameView.text = [dict valueForKey:@"title"];
    NSString *type = self.device.deviceType;
    
    //check which one should be used
    if([self.device.deviceType isEqualToString:@"fan"])
    {
        self.imageView.image = [UIImage imageNamed:@"fan.png"];
    }
    else if([type isEqualToString:@"thermostat"])
    {
        self.imageView.image = [UIImage imageNamed:@"thermostat.png"];
    }
    //for types with multiple icon possibilities we have to decide again
    else if([type isEqualToString:@"switchMultilevel"])
    {
        NSString *title = [self.device.metrics valueForKey:@"icon"];
        if([title isEqualToString:@"blinds"])
        {
            self.imageView.image = [UIImage imageNamed:@"blinds.png"];
        }
        else
            self.imageView.image = [UIImage imageNamed:@"light.png"];
    }
    else if([type isEqualToString:@"switchBinary"])
    {
        self.imageView.image = [UIImage imageNamed:@"switch.png"];
    }
    else if([type isEqualToString:@"toggleButton"])
    {
        self.imageView.image = [UIImage imageNamed:@"scene.png"];
    }
    else if([type isEqualToString:@"probe"] || [self.device.deviceType isEqualToString:@"battery"])
    {
        self.imageView.image = [UIImage imageNamed:@"battery.png"];
    }
    else if([type isEqualToString:@"doorlock"])
    {
        self.imageView.image = [UIImage imageNamed:@"door.png"];
    }
    //for types with multiple icon possibilities we have to decide again
    else if([type isEqualToString:@"sensorMultilevel"])
    {
        NSString *title = [self.device.metrics valueForKey:@"icon"];
        if([title isEqualToString:@"meter"])
        {
            if([[self.device.metrics valueForKey:@"scaleTitle"] isEqualToString:@"W"])
                self.imageView.image = [UIImage imageNamed:@"energy.png"];
            else 
                self.imageView.image = [UIImage imageNamed:@"meter"];
        }
        else if([title isEqualToString:@"temperature"])
        {
            self.imageView.image = [UIImage imageNamed:@"temperature.png"];
        }
        else if([title isEqualToString:@"luminosity"])
        {
            self.imageView.image = [UIImage imageNamed:@"luminosity.png"];
        }
        else if([title isEqualToString:@"humidity"])
        {
            self.imageView.image = [UIImage imageNamed:@"humidity.png"];
        }
        else if ([[dict valueForKey:@"icon"] rangeOfString:@"http"].location != NSNotFound)
        {
            NSData * imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString:[dict valueForKey:@"icon"]]];
            self.imageView.image = [UIImage imageWithData: imageData];
        }
        else
            self.imageView.hidden = YES;
    }
    //for types with multiple icon possibilities we have to decide again
    else if([type isEqualToString:@"sensorBinary"])
    {
        NSString *title = [self.device.metrics valueForKey:@"icon"];
        if([title isEqualToString:@"smoke"])
        {
            self.imageView.image = [UIImage imageNamed:@"smoke.png"];
        }
        else if([title isEqualToString:@"co"])
        {
            self.imageView.image = [UIImage imageNamed:@"co.png"];
        }
        else if([title isEqualToString:@"cooling"])
        {
            self.imageView.image = [UIImage imageNamed:@"cooling.png"];
        }
        else if([title isEqualToString:@"door"])
        {
            self.imageView.image = [UIImage imageNamed:@"door.png"];
        }
        else if([title isEqualToString:@"flood"])
        {
            self.imageView.image = [UIImage imageNamed:@"flood.png"];
        }
        else if([title isEqualToString:@"motion"])
        {
            self.imageView.image = [UIImage imageNamed:@"motion.png"];
        }
        else
        {
            if([[dict valueForKey:@"level"] isEqualToString:@"on"])
                self.imageView.image = [UIImage imageNamed:@"BinaryOn.png"];
            else
                self.imageView.image = [UIImage imageNamed:@"BinaryOff.png"];
        }
    }
}

//create a request with the specific URL of the device command
- (void)createRequestWithURL
{
    authent = [ZWayAuthentification new];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:30.0];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [request setValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
    
    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if(!theConnection)
        receivedData = nil;
}

- (void)updateState
{
    //Specified in subclasses
}

- (void)hideControls:(BOOL)editing
{
    //Specified in subclasses
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    receivedData = [NSMutableData new];
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    receivedData = nil;
    connection = nil;
    
    //alert user that the command failed
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CommandFail", @"") message:[error localizedDescription] delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil, nil];
    [alert show];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    receivedData = nil;
    connection = nil;
}

//method for outdoor redirect
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSMutableURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == YES)
        return [authent handleAuthentication:request withResponse:response];
    else
        return request;
}

@end
