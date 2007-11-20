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
  TreeHistory  *scanResult = [super runTaskWithInput: input];

  RescanTaskInput  *myInput = input;
  NSObject <FileItemTest>  *filterTest = [[myInput oldHistory] fileItemFilter];
  
  // Then filter ... (if not yet aborted, and there is actually a filter)
  if (scanResult != nil && filterTest != nil) {
    treeFilter = [[TreeFilter alloc] initWithFileItemTest: filterTest];
  
    DirectoryItem  *filteredVolumeTree = 
      [treeFilter filterVolumeTree: [scanResult volumeTree]];
  
    [treeFilter release];
    treeFilter = nil;
    
    return [[myInput oldHistory] historyAfterRescanning: filteredVolumeTree];
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
