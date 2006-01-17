#import <Cocoa/Cocoa.h>

@class BalancedTreeBuilder;
@class DirectoryViewControl;
@class ItemTreeDrawer;

// TODO: rename to ApplicationControl
@interface StartupControl : NSObject {

  IBOutlet NSPanel *progressPanel;
  IBOutlet NSTextField *progressText;
  IBOutlet NSProgressIndicator *progressIndicator;

  BalancedTreeBuilder  *treeBuilder;

  // Used for generating images that are to be saved to file. Created lazily.
  ItemTreeDrawer  *treeDrawer;  
}

- (IBAction) abort:(id)sender;
- (IBAction) openDirectoryView:(id)sender;
- (IBAction) duplicateDirectoryView:(id)sender;
- (IBAction) twinDirectoryView:(id)sender;
- (IBAction) saveDirectoryViewImage:(id)sender;

@end
