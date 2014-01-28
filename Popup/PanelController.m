#import "PanelController.h"
#import "BackgroundView.h"
#import "StatusItemView.h"
#import "MenubarController.h"

#define OPEN_DURATION .15
#define CLOSE_DURATION .1
#define TIME_UNTIL_CLOSE 3

#define SEARCH_INSET 17
#define WEB_INSET 17
#define WEB_TOP_INSET 48

//#define WEB_HEIGHT 300
//#define WEB_WIDTH 500
#define POPUP_HEIGHT 400
#define PANEL_WIDTH 600
#define MENU_ANIMATION_DURATION .5

#pragma mark -

@implementation PanelController

@synthesize backgroundView = _backgroundView;
@synthesize delegate = _delegate;
@synthesize searchField = _searchField;
@synthesize textField = _textField;

#pragma mark -

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate
{
    self = [super initWithWindowNibName:@"Panel"];
    if (self != nil)
    {
        _delegate = delegate;
        self.httpManager = [AFHTTPRequestOperationManager manager];

        NSError *error;
        self.cleanupRegex = [NSRegularExpression regularExpressionWithPattern:@"('(s|d)|\\.|,)" options:NSRegularExpressionCaseInsensitive error:&error];
        self.searchBaseURL = @"http://smartsign.imtc.gatech.edu/videos?keywords=";
        self.vidBaseURL = @"http://www.youtube.com/embed/";
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSControlTextDidEndEditingNotification object:self.searchField];
}

#pragma mark -

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Make a fully skinned panel
    NSPanel *panel = (id)[self window];
    [panel setAcceptsMouseMovedEvents:YES];
    [panel setLevel:NSPopUpMenuWindowLevel];
    [panel setOpaque:NO];
    [panel setBackgroundColor:[NSColor clearColor]];
    
    // Follow search string
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(runSearch) name:NSControlTextDidEndEditingNotification object:self.searchField];
}

#pragma mark - Public accessors

- (BOOL)hasActivePanel
{
    return _hasActivePanel;
}

- (void)setHasActivePanel:(BOOL)flag
{
    if (_hasActivePanel != flag)
    {
        _hasActivePanel = flag;
        
        if (_hasActivePanel)
        {
            [self openPanel];
        }
        else
        {
            [self closePanel];
        }
    }
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification
{
    self.hasActivePanel = NO;
}

- (void)windowDidResignKey:(NSNotification *)notification;
{
    if ([[self window] isVisible])
    {
        self.hasActivePanel = NO;
    }
}

- (void)windowDidResize:(NSNotification *)notification
{
    NSWindow *panel = [self window];
    NSRect statusRect = [self statusRectForWindow:panel];
    NSRect panelRect = [panel frame];
    
    CGFloat statusX = roundf(NSMidX(statusRect));
    CGFloat panelX = statusX - NSMinX(panelRect);
    
    self.backgroundView.arrowX = panelX;
    
    NSRect searchRect = [self.searchField frame];
    searchRect.size.width = NSWidth([self.backgroundView bounds]) - SEARCH_INSET * 2;
    searchRect.origin.x = SEARCH_INSET;
    searchRect.origin.y = NSHeight([self.backgroundView bounds]) - ARROW_HEIGHT - SEARCH_INSET - NSHeight(searchRect);
    
    if (NSIsEmptyRect(searchRect))
    {
        [self.searchField setHidden:YES];
    }
    else
    {
        [self.searchField setFrame:searchRect];
        [self.searchField setHidden:NO];
    }
    
    NSRect textRect = [self.textField frame];
    textRect.size.width = NSWidth([self.backgroundView bounds]) - SEARCH_INSET * 2;
    textRect.origin.x = SEARCH_INSET;
    textRect.size.height = NSHeight([self.backgroundView bounds]) - ARROW_HEIGHT - SEARCH_INSET * 3 - NSHeight(searchRect);
    textRect.origin.y = SEARCH_INSET;

    NSRect webRect = [self.myWebView frame];
    webRect.size.width = NSWidth([self.backgroundView bounds]) - WEB_INSET * 2;
    webRect.origin.x = WEB_INSET;
    webRect.size.height = NSHeight([self.backgroundView bounds]) - ARROW_HEIGHT - WEB_TOP_INSET - NSHeight(searchRect);
    webRect.origin.y = WEB_INSET;

    [self.myWebView setFrame: webRect];
    
    if (NSIsEmptyRect(textRect))
    {
        [self.textField setHidden:YES];
    }
    else
    {
        [self.textField setFrame:textRect];
        [self.textField setHidden:NO];
    }
}

#pragma mark - Keyboard

- (void)cancelOperation:(id)sender
{
    self.hasActivePanel = NO;
}

- (void)runSearch
{
//    NSString *searchFormat = @"";
    NSString *searchString = [self.searchField stringValue];
//    NSString *searchRequest = [NSString stringWithFormat:searchFormat, searchString];
//    [self.textField setStringValue:searchRequest];
    [self findSignForText:searchString andOpen:NO];
}

#pragma mark - Public methods

- (NSRect)statusRectForWindow:(NSWindow *)window
{
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = NSZeroRect;
    
    StatusItemView *statusItemView = nil;
    if ([self.delegate respondsToSelector:@selector(statusItemViewForPanelController:)])
    {
        statusItemView = [self.delegate statusItemViewForPanelController:self];
    }
    
    if (statusItemView)
    {
        statusRect = statusItemView.globalRect;
        statusRect.origin.y = NSMinY(statusRect) - NSHeight(statusRect);
    }
    else
    {
        statusRect.size = NSMakeSize(STATUS_ITEM_VIEW_WIDTH, [[NSStatusBar systemStatusBar] thickness]);
        statusRect.origin.x = roundf((NSWidth(screenRect) - NSWidth(statusRect)) / 2);
        statusRect.origin.y = NSHeight(screenRect) - NSHeight(statusRect) * 2;
    }
    return statusRect;
}

- (void)openPanel
{
    NSWindow *panel = [self window];
    
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = [self statusRectForWindow:panel];

    NSRect panelRect = [panel frame];
    panelRect.size.width = PANEL_WIDTH;
    panelRect.size.height = POPUP_HEIGHT;
    panelRect.origin.x = roundf(NSMidX(statusRect) - NSWidth(panelRect) / 2);
    panelRect.origin.y = NSMaxY(statusRect) - NSHeight(panelRect);
    
    if (NSMaxX(panelRect) > (NSMaxX(screenRect) - ARROW_HEIGHT))
        panelRect.origin.x -= NSMaxX(panelRect) - (NSMaxX(screenRect) - ARROW_HEIGHT);
    
    [NSApp activateIgnoringOtherApps:NO];
    [panel setAlphaValue:0];
    [panel setFrame:statusRect display:YES];
    [panel makeKeyAndOrderFront:nil];
    
    NSTimeInterval openDuration = OPEN_DURATION;
    
    NSEvent *currentEvent = [NSApp currentEvent];
    if ([currentEvent type] == NSLeftMouseDown)
    {
        NSUInteger clearFlags = ([currentEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);
        BOOL shiftPressed = (clearFlags == NSShiftKeyMask);
        BOOL shiftOptionPressed = (clearFlags == (NSShiftKeyMask | NSAlternateKeyMask));
        if (shiftPressed || shiftOptionPressed)
        {
            openDuration *= 10;
            
            if (shiftOptionPressed)
                NSLog(@"Icon is at %@\n\tMenu is on screen %@\n\tWill be animated to %@",
                      NSStringFromRect(statusRect), NSStringFromRect(screenRect), NSStringFromRect(panelRect));
        }
    }
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:openDuration];
    [[panel animator] setFrame:panelRect display:YES];
    [[panel animator] setAlphaValue:1];
    [NSAnimationContext endGrouping];
    
    [panel performSelector:@selector(makeFirstResponder:) withObject:self.searchField afterDelay:openDuration];
    
//    NSURL *myURL = [NSURL URLWithString:@"about:blank"];
//    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:myURL];
//    [[self.myWebView mainFrame] loadRequest:request];
}

- (void)closePanel
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:CLOSE_DURATION];
    [[[self window] animator] setAlphaValue:0];
    [NSAnimationContext endGrouping];
    
    dispatch_after(dispatch_walltime(NULL, NSEC_PER_SEC * CLOSE_DURATION * 2), dispatch_get_main_queue(), ^{
        [self.window orderOut:nil];
    });
}

#pragma mark - custom methods for text-ASL
- (void)findSignForText:(NSString *)text andOpen:(BOOL)bringToFront
{
    NSString *keywords = [self.cleanupRegex stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, [text length]) withTemplate:@""];

    NSString *escapedKeywords = [keywords stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];

    NSString *searchUrl = [NSString stringWithFormat:@"%@%@", self.searchBaseURL, escapedKeywords];
    [self.httpManager GET:searchUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         if ([responseObject count] != 0)
         {
             NSString *videoUrl = [NSString stringWithFormat:@"%@%@",
                                   self.vidBaseURL,
                                   [responseObject valueForKey:@"id"][0]];
             videoUrl = [videoUrl stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
             [[self.myWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:videoUrl]]];
             if (bringToFront)
             {
                 [self openPanel]; // cat
//                 dispatch_after(dispatch_walltime(NULL, NSEC_PER_SEC * TIME_UNTIL_CLOSE), dispatch_get_main_queue(), ^{
//                     [self.window orderOut:nil];
//                 });
             }
         } else {
             [self sendNotificationWithTitle:@"No ASL translation found" details:[NSString stringWithFormat:@"No video found for \"%@\"", keywords]];
             [[self.myWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
         }
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"%@", error);
         [self sendNotificationWithTitle:@"ASL Translator Error" details:[NSString stringWithFormat:@"%@", error]];
     }];

}

#pragma mark - NSUSerNotification methods
- (void)sendNotificationWithTitle:(NSString *)title details:(NSString *)details
{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    //    notification.responsePlaceholder = @"Reply";
    //    notification.hasReplyButton = true;
    notification.title = title;
    notification.informativeText = details;
    notification.soundName = NSUserNotificationDefaultSoundName;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    //    if (notification.activationType == NSUserNotificationActivationTypeReplied){
    //        NSString* userResponse = notification.response.string;
    //    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    return YES;
}



@end
