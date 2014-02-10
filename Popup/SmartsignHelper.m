//
//  SmartsignHelper.m
//  SmartSign Popup
//
//  Created by Tim Swihart on 2/7/14.
//
//

#import "SmartsignHelper.h"


#define MAX_KEYWORD_LENGTH 100


@implementation SmartsignHelper

+ (SmartsignHelper *) shared
{
    static dispatch_once_t onceToken;
    static SmartsignHelper * sharedSmartsignHelper;
    dispatch_once( &onceToken, ^ {
        sharedSmartsignHelper = [[self alloc] init];
    });
    return sharedSmartsignHelper;
}

- (id)init {
    self = [super init];
    if (self) {
        NSError *error;
        self.cleanupRegex = [NSRegularExpression regularExpressionWithPattern:@"('(s|d)|[.,?!\"';:\\-~])" options:NSRegularExpressionCaseInsensitive error:&error];
        self.searchBaseURL = @"http://smartsign.imtc.gatech.edu/videos?keywords=";
        self.vidBaseURL = @"http://www.youtube.com/embed/";
        self.vidOptions = @"?rel=0";
        self.alreadySearching = NO;
        self.httpManager = [AFHTTPRequestOperationManager manager];

    }
    return self;
}

/* Internal: given a string containing keywords search for the ASL translation
 * of the word or phrase
 *
 * text - The keywords to translate (currently only works for single words or phrases)
 * afterwards - callback to execute upon completion of the Sign search. When called from the hotkey binding this opens
 *    the panel. The callback is an empty function when this is called by the NSControlTextDidEndEditingNotification watcher
 *
 */
- (void)findSignForText:(NSString *)text afterwards:(void(^)())callbackBlock;
{
    if (self.alreadySearching != YES)
    {
        self.alreadySearching = YES;
        // Clean up the string: remove punctuation, etc.
        NSString *keywords = [self.cleanupRegex stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, [text length]) withTemplate:@""];
        
        // Limit the search string's length to 100 characters
        if (keywords.length > MAX_KEYWORD_LENGTH) {
            keywords = [keywords substringToIndex:MAX_KEYWORD_LENGTH];
        }
        
        NSString *escapedKeywords = [keywords stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
        
        NSString *searchUrl = [NSString stringWithFormat:@"%@%@", self.searchBaseURL, escapedKeywords];
        [self.httpManager GET:searchUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             if ([responseObject count] != 0)
             {
                 NSMutableArray *videoUrls = [[NSMutableArray alloc] init];
                 [responseObject enumerateObjectsUsingBlock:^(NSDictionary *video, NSUInteger idx, BOOL *stop) {
                     NSString *videoUrl = [NSString stringWithFormat:@"%@%@%@", self.vidBaseURL,[video valueForKey:@"id"], self.vidOptions];
                     videoUrl = [videoUrl stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
                     [videoUrls addObject: [NSURLRequest requestWithURL:[NSURL URLWithString:videoUrl]]];
                 }];
                 callbackBlock(videoUrls);
             } else {
                 [self sendNotificationWithTitle:@"No ASL translation found" details:[NSString stringWithFormat:@"No video found for \"%@\"", keywords]];
             }
             self.alreadySearching = NO;
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"%@", error);
             [self sendNotificationWithTitle:@"Smartsign Error" details:[NSString stringWithFormat:@"%@", error]];
             self.alreadySearching = NO;
         }];
    }
}

#pragma mark - NSUSerNotification methods
/* Internal: shorthand method to send notifications.
 *
 * title - The Notification's title
 * details - The descriptive text of the notification
 */
- (void)sendNotificationWithTitle:(NSString *)title details:(NSString *)details
{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    
    notification.title = title;
    notification.informativeText = details;
    notification.soundName = NSUserNotificationDefaultSoundName;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    return YES;
}

@end
