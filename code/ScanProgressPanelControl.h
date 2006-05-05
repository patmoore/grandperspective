#import <Cocoa/Cocoa.h>

@class BalancedTreeBuilder;
@class FileItem;

@interface ScanProgressPanelControl : NSWindowController {
  IBOutlet NSTextField  *progressText;
  IBOutlet NSProgressIndicator  *progressIndicator;
  
  BalancedTreeBuilder  *treeBuilder;
}

- (FileItem*) scanDirectory:(NSString*)dirName;

// Aborts the scanDirectory action (if ongoing).
- (IBAction) abort:(id)sender;

@end
