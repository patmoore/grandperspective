#import <Cocoa/Cocoa.h>


@protocol TaskExecutor;

@interface ProgressPanelControl : NSWindowController {
  IBOutlet NSProgressIndicator  *progressIndicator;
  IBOutlet NSTextField  *progressDetails;
  IBOutlet NSTextField  *progressSummary;
  
  NSTimeInterval  refreshRate;
  NSString  *detailsFormat;
  NSString  *summaryFormat;
  
  BOOL  taskRunning;
  NSObject <TaskExecutor>  *taskExecutor;

  NSObject  *cancelCallback;
  SEL  cancelCallbackSelector;
}

- (id) initWithTaskExecutor: (NSObject <TaskExecutor> *)taskExecutor;


- (NSObject <TaskExecutor> *) taskExecutor;


/* Signals that a task has started execution. It also provides the callback
 * method that should be called when the task execution finished. The panel
 * itself is notified about this by way of its -taskStopped method.
 *
 * It should be called from main thread.
 */
- (void) taskStartedWithInput: (id) taskInput
           cancelCallback: (NSObject *)callback selector: (SEL) selector;

/* Callback method. It should be called when the task has stopped executing,
 * either because it finished, or because it was aborted.
 *
 * It should be called from main thread.
 */
- (void) taskStopped;

/* Aborts the task (if it is still ongoing).
 */
- (IBAction) abort: (id) sender;

@end


@interface ProgressPanelControl (AbstractMethods)

- (NSString *)windowTitle;
- (NSString *)progressDetailsFormat;
- (NSString *)progressSummaryFormat;

- (NSString *)pathFromTaskInput: (id) taskInput;
- (NSDictionary *)progressInfo;

@end
