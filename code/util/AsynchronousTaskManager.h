#import <Cocoa/Cocoa.h>


@protocol TaskExecutor;

/* Manager that can run a task in a background thread. It only runs one task at 
 * most.
 */
@interface AsynchronousTaskManager : NSObject {

  NSObject <TaskExecutor>*  executor;

  NSConditionLock  *workLock;
  NSLock  *settingsLock;

  // "NO" iff the manager has not been disposed of.
  BOOL  alive;

  // Settings for the next task to run
  id  nextTaskInput;
  NSObject  *nextTaskCallback;
  SEL  nextTaskCallbackSelector; 
}

/* Initialises the manager with the task executor, which is responsible for
 * carrying out the actual tasks.
 */
- (id) initWithTaskExecutor: (NSObject <TaskExecutor>*)executor;

/* Call to free used resources (in particular the background thread that is 
 * being used).
 */
- (void) dispose;

- (NSObject <TaskExecutor>*) taskExecutor;

/* Aborts the currently running task (if any)
 */
- (void) abortTask;

/* Starts running a task with the given input. It should be invoked from the
 * main thread and the input should be immutable.
 *
 * If there is another task currently being carried out, it is cancelled. When 
 * the task has finished, the callback is called. If the task was aborted, the
 * callback will be invoked with a "nil" argument.
 */
- (void) asynchronouslyRunTaskWithInput: (id) input callback: (id) callback 
           selector: (SEL) selector;
           
@end
