#import <Cocoa/Cocoa.h>

@class BalancedTreeBuilder;
@class WindowManager;

@interface MainMenuControl : NSObject {

  IBOutlet NSPanel  *progressPanel;
  IBOutlet NSTextField  *progressText;
  IBOutlet NSProgressIndicator  *progressIndicator;
  
  BalancedTreeBuilder  *treeBuilder;
  WindowManager  *windowManager;
}

- (IBAction) abort:(id)sender;
- (IBAction) openDirectoryView:(id)sender;
- (IBAction) duplicateDirectoryView:(id)sender;
- (IBAction) twinDirectoryView:(id)sender;
- (IBAction) saveDirectoryViewImage:(id)sender;

@end
