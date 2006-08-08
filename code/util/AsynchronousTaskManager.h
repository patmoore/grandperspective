#import <Cocoa/Cocoa.h>


@protocol TaskExecutor;

// Runs tasks in the background. It only runs one task at most. If there is
// a request for a new task while there is another currently being carried
// out, the latter is being cancelled.
@interface AsynchronousTaskManager : NSObject {

  NSObject <TaskExecutor>*  executor;

  NSConditionLock  *workLock;
  NSLock  *settingsLock;
  BOOL  alive;

  // Settings for the next task to run
  id  nextTaskInput;
  NSObject  *nextTaskCallback;
  SEL  nextTaskCallbackSelector; 
}


- (id) initWithTaskExecutor: (NSObject <TaskExecutor>*)executor;

- (NSObject <TaskExecutor>*) taskExecutor;

// Call to free used resources (in particular the background thread that is 
// being used).
- (void) dispose;

// Note: input is assumed to be immutable. 
// Note: Should be called from main thread, and "callback" will be notified
// from main thread as well.
- (void) asynchronouslyRunTaskWithInput: (id) input callback: (id) callback 
           selector: (SEL) selector;

@end
