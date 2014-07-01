//
//  ZWayAuthentification.h
//  ZWay
//
//  Created by Lucas von Hacht on 01/07/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZWayAuthentification : NSObject <NSURLConnectionDataDelegate , NSURLConnectionDelegate>
{
    NSURL *original;
}

- (NSURLRequest*)handleAuthentication:(NSMutableURLRequest*)request withResponse:(NSURLResponse*)response;

@end
