#import "FilterTaskExecutor.h"

#import "TreeFilter.h"
#import "FilterTaskInput.h"
#import "TreeContext.h"


@implementation FilterTaskExecutor

- (id) init {
  if (self = [super init]) {
    taskLock = [[NSLock alloc] init];
    treeFilter = nil;
  }
  return self;
}

- (void) dealloc {
  [treeFilter release];
  
  [super dealloc];
}


- (void) prepareToRunTask {
  // Can be ignored because a one-shot object is used for running the task.
}

- (id) runTaskWithInput: (id) input {
  NSAssert( treeFilter==nil, @"treeFilter already set.");
  
  FilterTaskInput  *filterInput = input;
  
  [taskLock lock];
  treeFilter = [[TreeFilter alloc] initWithFilterSet: [filterInput filterSet]];
  [treeFilter setPackagesAsFiles: [filterInput packagesAsFiles]];
  [taskLock unlock];
    
  TreeContext  *originalTree = [filterInput treeContext];
  [originalTree obtainReadLock];

  TreeContext  *filteredTree = [treeFilter filterTree: originalTree];
                         
  [originalTree releaseReadLock];
  
  [taskLock lock];
  [treeFilter release];
  treeFilter = nil;
  [taskLock unlock];
  
  return filteredTree;
}

- (void) abortTask {
  [treeFilter abort];
}


- (NSDictionary *)progressInfo {
  NSDictionary  *dict;

  [taskLock lock];
  // The "taskLock" ensures that when treeFilter is not nil, the object will
  // always be valid when it is used (i.e. it won't be deallocated).
  dict = [treeFilter progressInfo];
  [taskLock unlock];
  
  return dict;
}

@end
