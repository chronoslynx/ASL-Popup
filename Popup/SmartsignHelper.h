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
@property NSRegularExpression *cleanupRegex;
@property NSString *searchBaseURL;
@property NSString *vidBaseURL;
@property NSString *vidOptions;
@property NSString *sandboxPath;
@property AFHTTPRequestOperationManager *httpManager;


+ (SmartsignHelper *) shared;
- (void)logSearchToFile:(NSString *)search;
- (void)findSignForText:(NSString *)text afterwards:(void(^)())callbackBlock; //andOpen:(BOOL)bringToFront;


@end
