//
//  SettingsWindow.h
//  SMARTSign-Assistant
//
//  Created by Tim Swihart on 4/18/14.
//
//

#import <Cocoa/Cocoa.h>
#import "MASShortcutView.h"

@interface SettingsWindow : NSWindow

@property(weak) IBOutlet MASShortcutView *shortcutView;

@end
