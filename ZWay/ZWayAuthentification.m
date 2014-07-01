//
//  ZWayAuthentification.m
//  ZWay
//
//  Created by Lucas von Hacht on 01/07/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import "ZWayAuthentification.h"
#import "ZWayAppDelegate.h"

@implementation ZWayAuthentification


-(NSURLRequest*)handleAuthentication:(NSMutableURLRequest *)request withResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger responseStatusCode = [httpResponse statusCode];
    
    NSString *urlString = [request.URL absoluteString];
    
    if ([urlString rangeOfString:@"ZAutomation"].location != NSNotFound)
        original = [NSURL URLWithString:urlString];
    
    //run original request
    if(responseStatusCode >= 300 && responseStatusCode <= 400)
    {
        request = [[NSMutableURLRequest alloc] initWithURL:original cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:30.0];
        
        [request setHTTPMethod:@"GET"];
        [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
        [request setValue:@"gzip, deflate, sdch" forHTTPHeaderField:@"Accept-Encoding"];
        return request;
    }
    //provide credentials
    else
    {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://find.z-wave.me/zboxweb"]];
        request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:30.0];
        
        NSString *postString = [NSString stringWithFormat:@"act=login&login=%@&pass=%@", ZWayAppDelegate.sharedDelegate.profile.userLogin, ZWayAppDelegate.sharedDelegate.profile.userPassword];
        NSData *myRequestData = [postString dataUsingEncoding: NSUTF8StringEncoding];
        
        [request setHTTPMethod:@"POST"];
        [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
        [request setValue:@"gzip, deflate, sdch" forHTTPHeaderField:@"Accept-Encoding"];
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[myRequestData length]] forHTTPHeaderField:@"Content-length"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
        [request setHTTPBody:myRequestData];
        return request;
    }
}

@end
