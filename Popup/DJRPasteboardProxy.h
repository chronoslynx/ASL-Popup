//
//  DJRPasteboardProxy.h
//  ASL Word to Sign
//
//  Created by Tim Swihart on 1/27/14.
//  Copyright (c) 2014 Tim Swihart. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DJRPasteboardProxy : NSObject

@property NSPasteboard *pasteboard;

+ (DJRPasteboardProxy *) shared;
+ (NSString*) selectedText;

@end
