#import <Cocoa/Cocoa.h>

#import "TaskExecutor.h"

@class TreeFilter;


@interface FilterTaskExecutor : NSObject <TaskExecutor> {
  BOOL  enabled;
  TreeFilter  *treeFilter;
}

@end
