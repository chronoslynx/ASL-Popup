#import "ApplicationDelegate.h"

#import "MASShortcutView.h"
#import "MASShortcutView+UserDefaults.h"
#import "MASShortcut+UserDefaults.h"
#import "MASShortcut+Monitoring.h"
#import "DJRPasteboardProxy.h"
#import "AFHTTPRequestOperationManager.h"

#import "SmartsignHelper.h"
#import "SettingsWindowController.h"

NSString *const SmartSignPreferenceKeyShortcut = @"SmartSignKeyboardShortcut";
NSString *const SmartSignPreferenceKeyShortcutEnabled = @"SmartSignShortcutEnabled";

typedef void (^HotkeyHandler)();

@implementation ApplicationDelegate

@synthesize panelController = _panelController;
@synthesize menubarController = _menubarController;

#pragma mark - Popup Setup Methods

- (void)dealloc {
  // Clean up our observer
  [_panelController removeObserver:self forKeyPath:@"hasActivePanel"];
}

void *kContextActivePanel = &kContextActivePanel;

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if (context == kContextActivePanel) {
    self.menubarController.hasActiveIcon = self.panelController.hasActivePanel;
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  // Install icon into the menu bar
  self.menubarController = [[MenubarController alloc] init];
  [self.shortcutView bind:@"enabled" toObject:self withKeyPath:@"shortcutEnabled" options:nil];
  self.shortcutView.associatedUserDefaultsKey = SmartSignPreferenceKeyShortcut;
  self.panelController.shortcutView = self.shortcutView;
  [self registerShortcut];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
  // Explicitly remove the icon from the menu bar
  self.menubarController = nil;
  // Explicitly remove the hotkey we reserved
  [self.shortcutView unbind:@"enabled"];
  return NSTerminateNow;
}

#pragma mark - Actions

- (IBAction)togglePanel:(id)sender {
  self.menubarController.hasActiveIcon = !self.menubarController.hasActiveIcon;
  self.panelController.hasActivePanel = self.menubarController.hasActiveIcon;
}

#pragma mark - Custom shortcut

- (BOOL)isShortcutEnabled {
  return [[NSUserDefaults standardUserDefaults] boolForKey:SmartSignPreferenceKeyShortcutEnabled];
}

- (void)setShortcutEnabled:(BOOL)enabled {
  if (self.shortcutEnabled != enabled) {
    /* If the user has never set a shortcut, set the default one here */
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:enabled forKey:SmartSignPreferenceKeyShortcutEnabled];
    MASShortcut *defaultShortcut =
        [MASShortcut shortcutWithKeyCode:kVK_F1 modifierFlags:NSControlKeyMask];
    [defaults setObject:[defaultShortcut data] forKey:SmartSignPreferenceKeyShortcut];
    [defaults synchronize];

    [self registerShortcut];
  }
}

- (void)registerShortcut {
  if (self.shortcutEnabled) {
    HotkeyHandler runSearch = ^{
        NSString *selectedText = [DJRPasteboardProxy selectedText];
        if (selectedText.length > 0) {
          // Make sure we avoid a retain cycle
          __weak typeof(self) weakSelf = self;
          [[SmartsignHelper shared] findSignForText:selectedText
                                         afterwards:^(NSArray *urls) {
                                             typeof(self) strongSelf = weakSelf;
                                             [strongSelf.panelController loadVideosFromArray:urls];
                                             [strongSelf togglePanel:nil];
                                         }];
        } else {
          [self togglePanel:nil];
        }
    };

    [MASShortcut registerGlobalShortcutWithUserDefaultsKey:SmartSignPreferenceKeyShortcut
                                                   handler:runSearch];
  } else {
    [MASShortcut unregisterGlobalShortcutWithUserDefaultsKey:SmartSignPreferenceKeyShortcut];
    [self setShortcutEnabled:YES];
  }
}

#pragma mark - Public accessors
/* Public: return access to the singleton panelController
 */
- (PanelController *)panelController {
  if (_panelController == nil) {
    _panelController = [[PanelController alloc] initWithDelegate:self];
    [_panelController addObserver:self
                       forKeyPath:@"hasActivePanel"
                          options:0
                          context:kContextActivePanel];
  }
  return _panelController;
}

#pragma mark - PanelControllerDelegate

- (StatusItemView *)statusItemViewForPanelController:(PanelController *)controller {
  return self.menubarController.statusItemView;
}

@end
