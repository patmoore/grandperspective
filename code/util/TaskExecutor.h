#import <Cocoa/Cocoa.h>

@protocol TaskExecutor

// Should return "nil" if the task has been aborted, and non-nil otherwise.
- (id) runTaskWithInput: (id)input;

// Aborts the currently running task, if any. As long as the executor is
// disabled, it should not accept any new tasks (but instead let 
// runTaskWithInput: return nil immediately).
- (void) disable;

// Enables the executor again.
- (void) enable;

@end
