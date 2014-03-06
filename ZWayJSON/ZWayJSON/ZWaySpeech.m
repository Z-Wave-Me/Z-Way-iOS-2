//
//  ZWaySpeech.m
//  ZWayJSON
//
//  Created by Lucas von Hacht on 3/5/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import "ZWaySpeech.h"
#import <OpenEars/LanguageModelGenerator.h>

@implementation ZWaySpeech

@synthesize pocketsphinxController;
@synthesize words;

- (void)setUpSpeech
{
    if(!self.pocketsphinxController.isListening)
    {
        LanguageModelGenerator *lmGenerator = [[LanguageModelGenerator alloc] init];
    
        NSString *name = @"SpeechCommands";
        NSError *err = [lmGenerator generateLanguageModelFromArray:words withFilesNamed:name forAcousticModelAtPath:[AcousticModel pathToModel:@"AcousticModelEnglish"]];
    
    
        NSDictionary *languageGeneratorResults = nil;
    
        NSString *lmPath = nil;
        NSString *dicPath = nil;
	
        if([err code] == noErr) {
        
            languageGeneratorResults = [err userInfo];
		
            lmPath = [languageGeneratorResults objectForKey:@"LMPath"];
            dicPath = [languageGeneratorResults objectForKey:@"DictionaryPath"];
		
        } else
            NSLog(@"Error: %@",[err localizedDescription]);
    
        [self.pocketsphinxController startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dicPath acousticModelAtPath:[AcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:NO];
    }
}

- (void)stopListening
{
    if(self.pocketsphinxController.isListening)
        [self.pocketsphinxController stopListening];
}

- (void)updateCommands:(NSArray*)array
{
    for(int i=0; i<array.count; i++)
    {
        NSString *title = [array objectAtIndex:i];
        if(![words containsObject:title])
            [words addObject:title];
    }
    self.words = words;
}

- (void)fixCommands
{
    words = [NSMutableArray arrayWithObjects:@"HEAT", @"OFF", @"COOL", @"ON", @"TEST", @"Hello", nil];
}

- (PocketsphinxController *)pocketsphinxController {
	if (pocketsphinxController == nil) {
		pocketsphinxController = [[PocketsphinxController alloc] init];
	}
	return pocketsphinxController;
}

@end
