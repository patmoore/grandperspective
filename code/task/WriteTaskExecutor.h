#import <Cocoa/Cocoa.h>

#import "TaskExecutor.h"

@class TreeWriter;

@interface WriteTaskExecutor : NSObject {
  BOOL  enabled;  
  TreeWriter  *treeWriter;
  
  NSLock  *taskLock;
}

/* Returns a dictionary with info about the progress of the write task that is 
 * currently being executed (or nil if there is none). The keys in the
 * dictionary are those used by TreeWriter.
 */
- (NSDictionary *)writeProgressInfo;

@end
