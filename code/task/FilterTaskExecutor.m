#import "FilterTaskExecutor.h"

#import "TreeFilter.h"
#import "FilterTaskInput.h"
#import "TreeHistory.h"


@implementation FilterTaskExecutor

- (id) init {
  if (self = [super init]) {
    enabled = YES;
  }
  return self;
}

- (void) dealloc {
  [treeFilter release];
  
  [super dealloc];
}


- (id) runTaskWithInput: (id) input {
  if (!enabled) {
    return nil;
  }
  
  NSAssert( treeFilter==nil, @"treeFilter already set.");
  
  FilterTaskInput  *filterInput = input;

  treeFilter = 
    [[TreeFilter alloc] initWithFileItemTest: [filterInput filterTest]];
  DirectoryItem  *filteredTree = 
    [treeFilter filterItemTree: [[filterInput oldHistory] itemTree]];
  
  [treeFilter release];
  treeFilter = nil;
  
  return [[filterInput oldHistory] historyAfterFiltering: filteredTree
                                     filter: [filterInput filterTest]];
}


- (void) disable {
  enabled = NO;

  [treeFilter abort];
}

- (void) enable {
  enabled = YES;
}

@end
