#import <Cocoa/Cocoa.h>


/* Result that should be returned by -runTaskWithInput to signal that a task 
 * with a "nil" result was carried out successfully.
 */
extern NSString  *SuccessfulVoidResult;


/* Classes that implement this protocol can be used to execute tasks in a 
 * background thread. The protocol is used to start tasks and to optionally 
 * abort them.
 */
@protocol TaskExecutor

/* Called just before -runTaskWithInput is invoked. Any outstanding request
 * to abort execution of the task (which may happen when the previous task
 * completed just while -abortTask was invoked) should be cleared.
 *
 * Invoked from the same thread as the subsequent call to -runTaskWithInput:.
 */
- (void) prepareToRunTask;

/* Run task with the given input and return the result. It should return "nil" 
 * iff the task has been aborted. It should return SuccessfulVoidResult when 
 * the task with a void result completes successfully.
 *
 * Invoked from a thread other than the main one.
 */
- (id) runTaskWithInput: (id) input;

/**
 * Aborts the task that is currently running. Invoking -abortTask multiple
 * times for the same task is allowed, and should not cause problems.
 *
 * Invoked from the main thread.
 */
- (void) abortTask;

@end
