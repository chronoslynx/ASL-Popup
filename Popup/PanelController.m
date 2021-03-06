#import "PanelController.h"
#import "BackgroundView.h"
#import "StatusItemView.h"
#import "MenubarController.h"
#import "SettingsWindowController.h"
#import "SettingsWindow.h"

#define OPEN_DURATION .15
#define CLOSE_DURATION .1
#define TIME_UNTIL_CLOSE 5

#define SEARCH_INSET 17
#define SETTINGS_BUTTON_INSET 12

#define WEB_HEIGHT 240
#define WEB_INSET 5
#define WEB_RIGHT_INSET 17

#define POPUP_HEIGHT 110
#define PANEL_WIDTH 430
#define MENU_ANIMATION_DURATION .5

#pragma mark -

@implementation PanelController

@synthesize backgroundView = _backgroundView;
@synthesize delegate = _delegate;
@synthesize searchField = _searchField;
@synthesize textField = _textField;
@synthesize webViews = _webViews;
@synthesize smartsignHelper = _smartsignHelper;

#pragma mark -

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate {
  self = [super initWithWindowNibName:@"Panel"];
  if (self != nil) {
    _delegate = delegate;
    _smartsignHelper = [SmartsignHelper shared];
    _webViews = [[NSArray alloc] init];
    _settingsWindowController = nil;
    _settingsController = nil;
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:NSControlTextDidEndEditingNotification
                                                object:self.searchField];
}

#pragma mark -

- (void)awakeFromNib {
  [super awakeFromNib];

  // Make a fully skinned panel
  NSPanel *panel = (id)[self window];
  [panel setAcceptsMouseMovedEvents:YES];
  [panel setLevel:NSPopUpMenuWindowLevel];
  [panel setOpaque:NO];
  [panel setBackgroundColor:[NSColor clearColor]];
  _settingsButton.title = @"\u2699";

  // Run the ASL search when editing done
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(runSearch)
                                               name:NSControlTextDidEndEditingNotification
                                             object:self.searchField];
}

#pragma mark - Public accessors

- (BOOL)hasActivePanel {
  return _hasActivePanel;
}

- (void)setHasActivePanel:(BOOL)flag {
  if (_hasActivePanel != flag) {
    _hasActivePanel = flag;

    if (_hasActivePanel) {
      [self openPanel];
    } else {
      self.searchField.stringValue = @"";
      [self closePanel];
    }
  }
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification {
  self.hasActivePanel = NO;
}

- (void)windowDidResignKey:(NSNotification *)notification;
{
  if ([[self window] isVisible]) {
    self.hasActivePanel = NO;
  }
}

- (void)windowDidResize:(NSNotification *)notification {
  // Deal with drawing the pane and placing objects.
  NSWindow *panel = [self window];
  NSRect statusRect = [self statusRectForWindow:panel];
  NSRect panelRect = [panel frame];

  CGFloat statusX = roundf(NSMidX(statusRect));
  CGFloat panelX = statusX - NSMinX(panelRect);

  self.backgroundView.arrowX = panelX;

  NSRect searchRect = [self.searchField frame];
  searchRect.size.width =
      NSWidth([self.backgroundView bounds]) - NSHeight(searchRect) * 2 - SEARCH_INSET;
  searchRect.origin.x = SEARCH_INSET;
  searchRect.origin.y =
      NSHeight([self.backgroundView bounds]) - ARROW_HEIGHT - SEARCH_INSET - NSHeight(searchRect);

  if (NSIsEmptyRect(searchRect)) {
    [self.searchField setHidden:YES];
  } else {
    [self.searchField setFrame:searchRect];
    [self.searchField setHidden:NO];
  }

  /* Place the textbox */
  NSRect textRect = [self.textField frame];
  textRect.size.width =
      searchRect.size.width;  // NSWidth([self.backgroundView bounds]) - SEARCH_INSET * 2;
  textRect.origin.x = SEARCH_INSET;
  textRect.size.height = NSHeight([self.backgroundView bounds]) - ARROW_HEIGHT - SEARCH_INSET * 3 -
                         NSHeight(searchRect);
  textRect.origin.y = SEARCH_INSET;

  if (NSIsEmptyRect(textRect)) {
    [self.textField setHidden:YES];
  } else {
    [self.textField setFrame:textRect];
    [self.textField setHidden:NO];
  }

  /* Place settings button */
  NSRect settingsRect = [_settingsButton frame];
  settingsRect.size.width = 24;
  settingsRect.size.height = 24;
  settingsRect.origin.x = searchRect.origin.x + searchRect.size.width + SETTINGS_BUTTON_INSET / 2;
  settingsRect.origin.y = searchRect.origin.y;

  if (NSIsEmptyRect(settingsRect)) {
    [self.settingsButton setHidden:YES];
  } else {
    [self.settingsButton setFrame:settingsRect];
    [self.settingsButton setHidden:NO];
  }
}

#pragma mark - Keyboard

- (void)cancelOperation:(id)sender {
  self.hasActivePanel = NO;
}

/* Internal: triggered by the NSControlTextDidEndEditingNotification. Runs the Sign search from the
 * search box's value */
- (void)runSearch {
  NSString *searchString = [self.searchField stringValue];
  if (searchString.length > 0) {
    __weak typeof(self) weakSelf = self;
    [_smartsignHelper findSignForText:searchString
                           afterwards:^(NSArray *urls) {
                               typeof(self) strongSelf = weakSelf;
                               [strongSelf loadVideosFromArray:urls];
                           }];
  }
}

#pragma mark - Public methods
/* Public: Builds the ScrollView's ContentView by creating and placing WebViews for each URL
 *
 * urls - NSArray of NSURLRequests used to build the WebViews
 *
 * Returns nothing
 */
- (void)loadVideosFromArray:(NSArray *)urls {
  if (urls.count > 0) {
    NSMutableArray *newWebViews = [[NSMutableArray alloc] init];
    NSRect scrollRect = [_scrollView frame];
    // Build each WebView and place them in the ContentView's frame
    [urls enumerateObjectsUsingBlock:^(NSURLRequest *obj, NSUInteger idx, BOOL *stop) {
        NSRect webRect = NSMakeRect(WEB_INSET, idx * (WEB_INSET + WEB_HEIGHT),
                                    scrollRect.size.width - WEB_RIGHT_INSET, WEB_HEIGHT);
        WebView *webView = [[WebView alloc] initWithFrame:webRect];
        [webView setFrame:webRect];
        [webView.mainFrame.frameView setAllowsScrolling:NO];
        [webView.mainFrame loadRequest:obj];
        [newWebViews addObject:webView];
    }];

    // Set the content view's new subviews
    _webViews = [NSArray arrayWithArray:newWebViews];
    [_scrollView.documentView
        setFrame:NSMakeRect(0, 0, scrollRect.size.width - 2 * WEB_INSET,
                            _webViews.count * WEB_HEIGHT + (_webViews.count - 1) * WEB_INSET)];
    [_scrollView.documentView setSubviews:_webViews];

    [_scrollView setNeedsDisplay:YES];
  }
}

- (NSRect)statusRectForWindow:(NSWindow *)window {
  NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
  NSRect statusRect = NSZeroRect;

  StatusItemView *statusItemView = nil;
  if ([self.delegate respondsToSelector:@selector(statusItemViewForPanelController:)]) {
    statusItemView = [self.delegate statusItemViewForPanelController:self];
  }

  if (statusItemView) {
    statusRect = statusItemView.globalRect;
    statusRect.origin.y = NSMinY(statusRect) - NSHeight(statusRect);
  } else {
    statusRect.size = NSMakeSize(STATUS_ITEM_VIEW_WIDTH, [[NSStatusBar systemStatusBar] thickness]);
    statusRect.origin.x = roundf((NSWidth(screenRect) - NSWidth(statusRect)) / 2);
    statusRect.origin.y = NSHeight(screenRect) - NSHeight(statusRect) * 2;
  }
  return statusRect;
}

/* Internal: animates the opening of the panel window */
- (void)openPanel {
  NSWindow *panel = [self window];

  NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
  NSRect statusRect = [self statusRectForWindow:panel];

  NSRect panelRect = [panel frame];
  panelRect.size.width = PANEL_WIDTH;
  panelRect.size.height = POPUP_HEIGHT + WEB_HEIGHT + 2 * WEB_INSET;
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
  if ([currentEvent type] == NSLeftMouseDown) {
    NSUInteger clearFlags = ([currentEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);
    BOOL shiftPressed = (clearFlags == NSShiftKeyMask);
    BOOL shiftOptionPressed = (clearFlags == (NSShiftKeyMask | NSAlternateKeyMask));
    if (shiftPressed || shiftOptionPressed) {
      openDuration *= 10;

      if (shiftOptionPressed)
        NSLog(@"Icon is at %@\n\tMenu is on screen %@\n\tWill be animated to %@",
              NSStringFromRect(statusRect), NSStringFromRect(screenRect),
              NSStringFromRect(panelRect));
    }
  }

  [NSAnimationContext beginGrouping];
  [[NSAnimationContext currentContext] setDuration:openDuration];
  [[panel animator] setFrame:panelRect display:YES];
  [[panel animator] setAlphaValue:1];
  [NSAnimationContext endGrouping];

  [panel performSelector:@selector(makeFirstResponder:)
              withObject:self.searchField
              afterDelay:openDuration];
}

/* Internal: animates the closing of the panel window */
- (void)closePanel {
  [NSAnimationContext beginGrouping];
  [[NSAnimationContext currentContext] setDuration:CLOSE_DURATION];
  [[[self window] animator] setAlphaValue:0];
  [NSAnimationContext endGrouping];

  dispatch_after(dispatch_walltime(NULL, NSEC_PER_SEC * CLOSE_DURATION * 2),
                 dispatch_get_main_queue(), ^{
      [self.window orderOut:nil];
      _webViews = [[NSArray alloc] init];
      [_scrollView.documentView setSubviews:_webViews];
  });
}

/*
 *
 */

- (IBAction)showSettingsWindow:(id)sender {
  _settingsController = [[SettingsWindowController alloc] initWithWindowNibName:@"SettingsWindow"];
  ((SettingsWindow *)(_settingsController.window)).shortcutView = _shortcutView;
  [_settingsController showWindow:nil];
}
@end
