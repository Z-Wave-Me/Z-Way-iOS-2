//
//  ZWayLanguage.m
//  ZWayJSON
//
//  Created by Lucas von Hacht on 24/06/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import <objc/runtime.h>

static const char _bundle=0;

@interface BundleEx : NSBundle
@end

@implementation BundleEx
//override localizedString method
-(NSString*)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName
{
    NSBundle* bundle=objc_getAssociatedObject(self, &_bundle);
    return bundle ? [bundle localizedStringForKey:key value:value table:tableName] : [super localizedStringForKey:key value:value table:tableName];
}
@end

@implementation NSBundle (Language)
//set app language
+(void)setLanguage:(NSString*)language
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      object_setClass([NSBundle mainBundle],[BundleEx class]);
                  });
    objc_setAssociatedObject([NSBundle mainBundle], &_bundle, language ? [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:language ofType:@"lproj"]] : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
