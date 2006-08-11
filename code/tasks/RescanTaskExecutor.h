#import <Cocoa/Cocoa.h>

#import "TaskExecutor.h"

@class TreeBuilder;
@class TreeFilter;


@interface RescanTaskExecutor : NSObject <TaskExecutor> {
  BOOL  enabled;  
  TreeBuilder  *treeBuilder;
  TreeFilter  *treeFilter;
}

@end
