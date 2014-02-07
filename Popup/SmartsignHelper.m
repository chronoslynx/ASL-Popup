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
        self.vidOptions = @"?autoplay=1";
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
    if (self.alreadySearching == YES)
    {
        //TODO: Figure out why NSControlTextDidEndEditingNotification is sent when the panel opens from hotkey
        NSLog(@"Already searching for a sign");
    }
    else
    {
        self.alreadySearching = YES;
        // Clean up the string: remove punctuation, etc.
        NSString *keywords = [self.cleanupRegex stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, [text length]) withTemplate:@""];
        
        // Limit the search string's length to 100 characters
        if (keywords.length > MAX_KEYWORD_LENGTH) {
            keywords = [keywords substringToIndex:MAX_KEYWORD_LENGTH];
        }
        NSLog(@"Keywords: %@", keywords);
        
        NSString *escapedKeywords = [keywords stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
        
        NSString *searchUrl = [NSString stringWithFormat:@"%@%@", self.searchBaseURL, escapedKeywords];
        [self.httpManager GET:searchUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSMutableArray *videoUrls = [[NSMutableArray alloc] init];
             if ([responseObject count] != 0)
             {
                 
                 [responseObject enumerateObjectsUsingBlock:^(NSString *videoID, NSUInteger idx, BOOL *stop) {
                     NSString *videoUrl = [NSString stringWithFormat:@"%@%@%@",
                                           self.vidBaseURL,
                                           [responseObject valueForKey:@"id"][0],
                                           self.vidOptions];
                     videoUrl = [videoUrl stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
//                     [videoUrls addObject: [videoUrl stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
                     [videoUrls addObject: [NSURLRequest requestWithURL:[NSURL URLWithString:videoUrl]]];
                 }];
                 //TODO: need to build a list of videos
                 
//                 [[self.myWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:videoUrl]]];
                 
             } else {
                 [self sendNotificationWithTitle:@"No ASL translation found" details:[NSString stringWithFormat:@"No video found for \"%@\"", keywords]];
                 [videoUrls addObject: [NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
             }
             callbackBlock(videoUrls); //TODO: callbackBlock should take an array of videos to present.

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
