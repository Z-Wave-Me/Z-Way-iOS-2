//
//  ZWDataHandler.h
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/17/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZWDevice.h"
#import "ZWayAuthentification.h"

@interface ZWDataHandler : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate>
{
    NSMutableData *receivedData;
    NSMutableArray *locationTitles;
    NSMutableArray *locationIDs;
    ZWayAuthentification *authent;
    BOOL alertShown;
}

@property (nonatomic, strong) NSMutableArray *locationTitles;
@property (nonatomic, strong) NSMutableArray *locationIDs;
@property (nonatomic, strong) ZWayAuthentification *authent;

- (NSUInteger)getTimestamp:(NSDictionary *)dictionary firstTime:(BOOL)first;
- (void)getLocations;
- (void)setUpAuth;

@end
