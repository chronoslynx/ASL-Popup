//
//  ApplicationDelegate.h
//  ASL Popup
//
//  Modified by Tim Swihart on 1/27/14.
//

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

#import "MenubarController.h"
#import "PanelController.h"

@interface ApplicationDelegate : NSObject <NSApplicationDelegate, PanelControllerDelegate>

@property (nonatomic, strong) MenubarController *menubarController;
@property (nonatomic, strong, readonly) PanelController *panelController;
@property DDHotKeyCenter* hotKeyCenter;


//@property (weak) IBOutlet NSTextField *textField;
//@property (weak) IBOutlet NSTextField *textLabel;
//@property (weak) IBOutlet NSButton *translateButton;
//@property (weak) IBOutlet WebView *webView;


- (IBAction)togglePanel:(id)sender;

@end
