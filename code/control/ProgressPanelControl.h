#import <Cocoa/Cocoa.h>


@interface ProgressPanelControl : NSWindowController {
  IBOutlet NSTextField  *progressText;
  IBOutlet NSProgressIndicator  *progressIndicator;
  
  NSString  *title;
  
  NSObject  *cancelCallback;
  SEL  cancelCallbackSelector;
}

- (id) initWithTitle: (NSString*) title;

// Should be called from main thread.
- (void) taskStarted: (NSString*) taskDescription
           cancelCallback: (NSObject*) callback selector: (SEL) selector;
// Should be called from main thread.
- (void) taskStopped;

// Aborts the task (if ongoing).
- (IBAction) abort: (id) sender;

@end
