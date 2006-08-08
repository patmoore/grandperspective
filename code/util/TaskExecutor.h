#import <Cocoa/Cocoa.h>

@protocol TaskExecutor

/* Should return "nil" if the task has been aborted, and non-nil otherwise.
 *
 * Invoked from a thread other than the main one.
 */
- (id) runTaskWithInput: (id) input;

/* Aborts the currently running task, if any. As long as the executor is
 * disabled, it should not accept any new tasks (but instead let 
 * runTaskWithInput: return nil immediately).
 *
 * Invoked from the main thread.
 */
- (void) disable;

/* Enables the executor again.
 *
 * Invoked from the main thread.
 */
- (void) enable;

@end
