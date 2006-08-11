#import <Cocoa/Cocoa.h>

#import "TaskExecutor.h"

@class TreeBuilder;

@interface ScanTaskExecutor : NSObject <TaskExecutor> {
  BOOL  enabled;  
  TreeBuilder  *treeBuilder;
}

@end
