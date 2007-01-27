#import "RescanTaskExecutor.h"

#import "TreeFilter.h"
#import "TreeBuilder.h"
#import "RescanTaskInput.h"


@implementation RescanTaskExecutor

- (id) init {
  if (self = [super init]) {
    enabled = YES;
  }
  return self;
}

- (void) dealloc {
  [treeBuilder release];
  [treeFilter release];
  
  [super dealloc];
}


- (id) runTaskWithInput: (id) input {
  if (!enabled) {
    return nil;
  }
  
  RescanTaskInput  *myInput = input;
  
  // First scan ...
  treeBuilder = [[TreeBuilder alloc] init];
  [treeBuilder setFileSizeType: [myInput fileSizeType]];
  
  DirectoryItem*  itemTree = 
    [treeBuilder buildTreeForPath: [myInput directoryName]];
  
  [treeBuilder release];
  treeBuilder = nil;

  // Then filter ... (if not yet aborted, and there is actually a filter)
  if (itemTree != nil && [myInput filterTest] != nil) {
    treeFilter = 
      [[TreeFilter alloc] initWithFileItemTest: [myInput filterTest]];
  
    itemTree = [treeFilter filterItemTree: itemTree];
  
    [treeFilter release];
    treeFilter = nil;
  }
  
  return itemTree;
}


- (void) disable {
  enabled = NO;

  [treeBuilder abort];
  [treeFilter abort];
}

- (void) enable {
  enabled = YES;
}

@end
