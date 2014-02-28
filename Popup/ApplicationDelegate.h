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

@class MASShortcutView;

@interface ApplicationDelegate : NSObject<NSApplicationDelegate, PanelControllerDelegate>

@property(nonatomic, strong) MenubarController *menubarController;
@property(nonatomic, strong, readonly) PanelController *panelController;
@property(nonatomic, weak) IBOutlet MASShortcutView *shortcutView;
@property(nonatomic, strong) NSWindowController *settingsWindowController;
@property(nonatomic, getter=isShortcutEnabled) BOOL shortcutEnabled;

- (IBAction)togglePanel:(id)sender;

@end
