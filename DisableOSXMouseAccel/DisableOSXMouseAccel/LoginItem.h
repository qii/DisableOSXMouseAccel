//
// Created by qii on 7/25/15.
// Copyright (c) 2015 qii. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LoginItem : NSObject
+ (BOOL) willStartAtLogin:(NSURL *)itemURL;
+ (void) setStartAtLogin:(NSURL *)itemURL enabled:(BOOL)enabled;
@end