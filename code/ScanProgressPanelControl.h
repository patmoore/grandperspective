#import <Cocoa/Cocoa.h>

@class BalancedTreeBuilder;

@interface ScanProgressPanelControl : NSWindowController {
  IBOutlet NSTextField  *progressText;
  IBOutlet NSProgressIndicator  *progressIndicator;
  
  BalancedTreeBuilder  *treeBuilder;

  id  callBack;
  SEL  callBackSelector;
}

- (id) initWithCallBack:(id)callBack selector:(SEL)selector;

// Can be invoked in a different thread.
- (void) scanDirectory:(NSString*)dirName;

// Aborts the scanDirectory action (if ongoing).
- (IBAction) abort:(id)sender;

@end
