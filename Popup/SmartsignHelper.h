//
//  SmartsignHelper.h
//  SmartSign Popup
//
//  Created by Tim Swihart on 2/7/14.
//
//

#import <Foundation/Foundation.h>
#import "AFHTTPRequestOperationManager.h"


@interface SmartsignHelper : NSObject

@property BOOL alreadySearching;
@property (readonly, weak) NSRegularExpression *cleanupRegex;
@property (readonly, weak) NSString *searchBaseURL;
@property (readonly, weak) NSString *vidBaseURL;
@property (readonly, weak) NSString *vidOptions;
@property (readonly, weak) NSString *logFolder;
@property (readonly, weak) NSString *logPrefix;
//@property NSFileHandle *logFileHandle;
@property (readonly, weak) AFHTTPRequestOperationManager *httpManager;


+ (SmartsignHelper *) shared;
- (void)ensureLogDirectory;
- (void)logSearchToFile:(NSString *)search;
- (void)findSignForText:(NSString *)text afterwards:(void(^)())callbackBlock;


@end
