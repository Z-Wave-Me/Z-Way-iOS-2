//
//  ZWDeviceItem.m
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/20/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import "ZWDeviceItem.h"
#import "ZWDevice.h"
#import "SWTableViewCell.h"

@implementation ZWDeviceItem

@synthesize nameView = _nameView;
@synthesize device = _device;

- (void)setDisplayName
{
    NSDictionary *dict = self.device.metrics;
    self.nameView.text = [dict valueForKey:@"title"];
    
    if([self.device.deviceType isEqualToString:@"fan"])
        self.imageView.image = [UIImage imageNamed:@"fan.png"];
    else if([self.device.deviceType isEqualToString:@"thermostat"])
        self.imageView.image = [UIImage imageNamed:@"thermostat.png"];
    else if([self.device.deviceType isEqualToString:@"switchMultilevel"])
        self.imageView.image = [UIImage imageNamed:@"light.png"];
    else if([self.device.deviceType isEqualToString:@"switchBinary"])
        self.imageView.image = [UIImage imageNamed:@"switch.png"];
    else if([self.device.deviceType isEqualToString:@"probe"] || [self.device.deviceType isEqualToString:@"battery"])
        self.imageView.image = [UIImage imageNamed:@"battery.png"];
}

- (void)createRequestWithURL
{
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
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectionFail", @"") message:[error localizedDescription] delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil, nil];
    [alert show];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    attempts = 0;
    receivedData = nil;
    connection = nil;
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSMutableURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    if([ZWayAppDelegate.sharedDelegate.profile.useOutdoor boolValue] == YES)
    {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        int responseStatusCode = [httpResponse statusCode];
        
        if(responseStatusCode >= 300 && responseStatusCode <= 400 && attempts == 1)
        {
            request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:30.0];
            
            [request setHTTPMethod:@"GET"];
            [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
            [request setValue:@"gzip, deflate, sdch" forHTTPHeaderField:@"Accept-Encoding"];
            attempts = 2;
            return request;
        }
        else if(attempts == 0)
        {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"http://find.z-wave.me/zboxweb"]];
            request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:30.0];
            
            NSString *postString = [NSString stringWithFormat:@"act=login&login=%@&pass=%@", ZWayAppDelegate.sharedDelegate.profile.userLogin, ZWayAppDelegate.sharedDelegate.profile.userPassword];
            NSData *myRequestData = [postString dataUsingEncoding: NSUTF8StringEncoding];
            
            [request setHTTPMethod:@"POST"];
            [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
            [request setValue:@"gzip, deflate, sdch" forHTTPHeaderField:@"Accept-Encoding"];
            [request setValue:[NSString stringWithFormat:@"%d", [myRequestData length]] forHTTPHeaderField:@"Content-length"];
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
            [request setHTTPBody:myRequestData];
            attempts = 1;
            return request;
        }
        else
        {
            [connection cancel];
            return nil;
        }
    }
    else
        return request;
}

@end
