#import <Cocoa/Cocoa.h>

@protocol TaskExecutor

// Should return "nil" if the task has been aborted, and non-nil otherwise.
- (id) runTaskWithInput: (id)input;

- (void) abortTask;
- (void) resetAbortTaskFlag;

@end
