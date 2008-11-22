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

/* Run task with the given input and return the result. It should return "nil" 
 * iff the task has been aborted. It should return SuccessfulVoidResult when 
 * the task with a void result completes successfully.
 *
 * Invoked from a thread other than the main one.
 */
- (id) runTaskWithInput: (id) input;

/**
 * Aborts the task that is currently running.
 *
 * Invoked from the main thread.
 */
- (void) abortTask;

@end
