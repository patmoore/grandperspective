#import "RescanTaskExecutor.h"

#import "TreeFilter.h"
#import "RescanTaskInput.h"
#import "TreeHistory.h"


@implementation RescanTaskExecutor

- (void) dealloc {
  [treeFilter release];
  
  [super dealloc];
}


- (id) runTaskWithInput: (id) input {
  TreeContext  *scanResult = [super runTaskWithInput: input];

  RescanTaskInput  *myInput = input;
  NSObject <FileItemTest>  *filterTest = [[myInput oldContext] fileItemFilter];
  
  // Then filter ... (if not yet aborted, and there is actually a filter)
  if (scanResult != nil && filterTest != nil) {
    treeFilter = [[TreeFilter alloc] initWithFileItemTest: filterTest];
  
    TreeContext  *filteredResult = [treeFilter filterTree: scanResult];
  
    [treeFilter release];
    treeFilter = nil;
    
    return filteredResult;
  }
  else {
    return scanResult;
  }
}


- (void) disable {
  [super disable];

  [treeFilter abort];
}

@end
