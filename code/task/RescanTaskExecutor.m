#import "RescanTaskExecutor.h"

#import "TreeFilter.h"
#import "RescanTaskInput.h"


@implementation RescanTaskExecutor

- (void) dealloc {
  [treeFilter release];
  
  [super dealloc];
}


- (id) runTaskWithInput: (id) input {
  DirectoryItem*  itemTree = [super runTaskWithInput: input];

  RescanTaskInput  *myInput = input;
  
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
  [super disable];

  [treeFilter abort];
}

@end
