#import <Cocoa/Cocoa.h>

#import "TaskExecutor.h"

@class TreeBuilder;

@interface ScanTaskExecutor : NSObject <TaskExecutor> {
  BOOL  enabled;  
  TreeBuilder  *treeBuilder;
  
  NSLock  *taskLock;
}


/* Returns a dictionary with info about the progress of the scan task that is 
 * currently being executed (or nil if there is none). The keys in the
 * dictionary are those used by TreeBuilder.
 */
- (NSDictionary *)scanProgressInfo;

@end
