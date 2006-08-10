#import "FilterTaskExecutor.h"

#import "TreeFilter.h"
#import "FilterTaskInput.h"


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
  DirectoryItem  *itemTree = 
    [treeFilter filterItemTree: [filterInput itemTree]];
  
  [treeFilter release];
  treeFilter = nil;
  
  return itemTree;
}


- (void) disable {
  enabled = NO;

  [treeFilter abort];
}

- (void) enable {
  enabled = YES;
}

@end
