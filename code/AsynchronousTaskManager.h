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
  id  nextTaskCallBack;
  SEL  nextTaskCallBackSelector; 
}


- (id) initWithTaskExecutor: (NSObject <TaskExecutor>*)executor;

// Call to free used resources (in particular the background thread that is 
// being used).
- (void) dispose;

// Note: input is assumed to be immutable. 
// Note: Should be called from main thread, and callBack will be notified
// from main thread as well.
- (void) asynchronouslyRunTaskWithInput:(id)input callBack:(id)callBack 
           selector:(SEL)selector;

@end
