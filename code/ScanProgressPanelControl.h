#import <Cocoa/Cocoa.h>

@class TreeBuilder;
@class FileItem;

@interface ScanProgressPanelControl : NSWindowController {
  IBOutlet NSTextField  *progressText;
  IBOutlet NSProgressIndicator  *progressIndicator;
  
  TreeBuilder  *treeBuilder;
}

- (FileItem*) scanDirectory:(NSString*)dirName;

// Aborts the scanDirectory action (if ongoing).
- (IBAction) abort:(id)sender;

@end
