//
//  ZWaySpeech.h
//  ZWayJSON
//
//  Created by Lucas von Hacht on 3/5/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenEars/PocketsphinxController.h>
#import <OpenEars/AcousticModel.h>

@interface ZWaySpeech : NSObject
{
    PocketsphinxController *pocketsphinxController;
    NSMutableArray *commands;
    NSMutableArray *words;
}

@property (strong, nonatomic) PocketsphinxController *pocketsphinxController;
@property (strong, nonatomic) NSMutableArray *words;

- (void)setUpSpeech;
- (void)updateCommands:(NSArray*)array;
- (void)fixCommands;
- (void)stopListening;

@end
