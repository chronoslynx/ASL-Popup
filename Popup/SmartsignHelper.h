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
@property(readonly) NSRegularExpression *cleanupRegex;
@property(readonly) NSString *searchBaseURL;
@property(readonly) NSString *vidBaseURL;
@property(readonly) NSString *vidOptions;
@property(readonly) NSString *logFolder;
@property(readonly) NSString *logPrefix;
//@property NSFileHandle *logFileHandle;
@property(readonly) AFHTTPRequestOperationManager *httpManager;

+ (SmartsignHelper *)shared;
- (void)ensureLogDirectory;
- (void)logSearchToFile:(NSString *)search;
- (void)findSignForText:(NSString *)text afterwards:(void (^)())callbackBlock;

@end
