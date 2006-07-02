#import <Cocoa/Cocoa.h>

@class TreeBuilder;
@class DirectoryItem;

@interface ScanProgressPanelControl : NSWindowController {
  IBOutlet NSTextField  *progressText;
  IBOutlet NSProgressIndicator  *progressIndicator;
  
  TreeBuilder  *treeBuilder;
}

- (DirectoryItem*) scanDirectory:(NSString*)dirName;

// Aborts the scanDirectory action (if ongoing).
- (IBAction) abort:(id)sender;

@end
