#import "ApplicationDelegate.h"
#import "DJRPasteboardProxy.h"
#import "AFHTTPRequestOperationManager.h"

@implementation ApplicationDelegate

@synthesize panelController = _panelController;
@synthesize menubarController = _menubarController;


#pragma mark - Popup Setup Methods

- (void)dealloc
{
    // Clean up our observer
    [_panelController removeObserver:self forKeyPath:@"hasActivePanel"];
}

void *kContextActivePanel = &kContextActivePanel;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == kContextActivePanel) {
        self.menubarController.hasActiveIcon = self.panelController.hasActivePanel;
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    // Install icon into the menu bar
    self.menubarController = [[MenubarController alloc] init];
    self.hotKeyCenter = [DDHotKeyCenter sharedHotKeyCenter];

    [self registerGlobalHotkey];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Explicitly remove the icon from the menu bar
    self.menubarController = nil;
    // Explicitly remove the hotkey we reserved
    [self deregisterGlobalHotkey];
    return NSTerminateNow;
}

#pragma mark - Actions

- (IBAction)togglePanel:(id)sender
{
    self.menubarController.hasActiveIcon = !self.menubarController.hasActiveIcon;
    self.panelController.hasActivePanel = self.menubarController.hasActiveIcon;
}

#pragma mark - DDHotKey functions
- (void) registerGlobalHotkey
{
    // Hotkey is CTRL-F1 currently. TODO: add configurable hotkey
	if (![self.hotKeyCenter registerHotKeyWithKeyCode:kVK_F1 modifierFlags:NSControlKeyMask
                                               target:self action:@selector(hotkeyWithEvent:)
                                               object:nil]) {
        NSLog(@"Error registering hotkey");
	}
}

-(void) deregisterGlobalHotkey
{
    [self.hotKeyCenter unregisterHotKeyWithKeyCode:kVK_F1 modifierFlags:NSControlKeyMask];
}

- (void) hotkeyWithEvent:(NSEvent *)hkEvent {
    NSString *selectedText = [DJRPasteboardProxy selectedText];
    if (selectedText.length > 0)
    {
        // Make sure we avoid a retain cycle
        __weak typeof(self) weakSelf = self;
        [[self panelController] findSignForText:selectedText afterwards:^(void){
            typeof(self) strongSelf = weakSelf;
            [strongSelf togglePanel:nil];
        }];
    } else {
        [self togglePanel:nil];
    }
}

#pragma mark - Public accessors
/* Public: return access to the singleton panelController
 */
- (PanelController *)panelController
{
    if (_panelController == nil) {
        _panelController = [[PanelController alloc] initWithDelegate:self];
        [_panelController addObserver:self forKeyPath:@"hasActivePanel" options:0 context:kContextActivePanel];
    }
    return _panelController;
}

#pragma mark - PanelControllerDelegate

- (StatusItemView *)statusItemViewForPanelController:(PanelController *)controller
{
    return self.menubarController.statusItemView;
}

@end
