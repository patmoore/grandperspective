#import <Cocoa/Cocoa.h>

#import "TaskExecutor.h"

@class TreeFilter;


@interface FilterTaskExecutor : NSObject <TaskExecutor> {
  TreeFilter  *treeFilter;
  
  NSLock  *taskLock;
}

/* Returns a dictionary with info about the progress of the filter task that is 
 * currently being executed (or nil if there is none). The keys in the
 * dictionary are those used by ProgressInfo.
 */
- (NSDictionary *)progressInfo;

@end
