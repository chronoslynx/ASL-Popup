#import "BackgroundView.h"
#import "StatusItemView.h"
#import "DDHotKeyCenter.h"
#import "SmartsignHelper.h"

#import <WebKit/WebKit.h>

@class PanelController;

@protocol PanelControllerDelegate<NSObject>

@optional

- (StatusItemView *)statusItemViewForPanelController:(PanelController *)controller;

@end

#pragma mark -

@interface PanelController : NSWindowController<NSWindowDelegate> {
  BOOL _hasActivePanel;
  __unsafe_unretained BackgroundView *_backgroundView;
  __unsafe_unretained id<PanelControllerDelegate> _delegate;
  __unsafe_unretained NSSearchField *_searchField;
  __unsafe_unretained NSTextField *_textField;
}

@property(nonatomic, unsafe_unretained) IBOutlet BackgroundView *backgroundView;
@property(nonatomic, unsafe_unretained) IBOutlet NSSearchField *searchField;
@property(nonatomic, unsafe_unretained) IBOutlet NSTextField *textField;
//@property (strong) IBOutlet WebView *myWebView;
@property(nonatomic, strong) NSArray *webViews;
@property(strong) IBOutlet NSScrollView *scrollView;

@property(nonatomic) BOOL hasActivePanel;
@property(nonatomic, unsafe_unretained, readonly) id<PanelControllerDelegate> delegate;
@property(nonatomic, readonly) SmartsignHelper *smartsignHelper;

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate;

- (void)openPanel;
- (void)closePanel;
- (void)loadVideosFromArray:(NSArray *)urls;

@end
