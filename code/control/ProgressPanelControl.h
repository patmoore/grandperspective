#import <Cocoa/Cocoa.h>


@protocol TaskExecutor;

@interface ProgressPanelControl : NSWindowController {
  IBOutlet NSProgressIndicator  *progressIndicator;
  IBOutlet NSTextField  *progressDetails;
  IBOutlet NSTextField  *progressSummary;
  
  BOOL  taskRunning;
  NSObject <TaskExecutor>  *taskExecutor;

  NSObject  *cancelCallback;
  SEL  cancelCallbackSelector;
}

- (id) initWithTaskExecutor: (NSObject <TaskExecutor> *)taskExecutor;


- (NSObject <TaskExecutor> *) taskExecutor;


// Should be called from main thread.
- (void) taskStartedWithInput: (id) taskInput
           cancelCallback: (NSObject *)callback selector: (SEL) selector;
// Should be called from main thread.
- (void) taskStopped;

// Aborts the task (if ongoing).
- (IBAction) abort: (id) sender;

@end


@interface ProgressPanelControl (ProtectedMethods)

- (void) initProgressInfoForTaskWithInput: (id) taskInput;
- (void) updateProgressInfo;

@end
