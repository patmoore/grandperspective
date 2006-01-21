#import <Cocoa/Cocoa.h>

@class BalancedTreeBuilder;

// TODO: rename to ApplicationControl
@interface StartupControl : NSObject {

  IBOutlet NSPanel *progressPanel;
  IBOutlet NSTextField *progressText;
  IBOutlet NSProgressIndicator *progressIndicator;
  
  BalancedTreeBuilder  *treeBuilder;
}

- (IBAction) abort:(id)sender;
- (IBAction) openDirectoryView:(id)sender;
- (IBAction) duplicateDirectoryView:(id)sender;
- (IBAction) twinDirectoryView:(id)sender;
- (IBAction) saveDirectoryViewImage:(id)sender;

@end
