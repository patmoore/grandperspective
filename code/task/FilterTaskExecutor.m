#import "FilterTaskExecutor.h"

#import "TreeFilter.h"
#import "FilterTaskInput.h"
#import "FilteredTreeGuide.h"
#import "TreeContext.h"


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
  FilteredTreeGuide  *treeGuide = 
    [[[FilteredTreeGuide alloc] 
         initWithFileItemTest: [filterInput filterTest]
           packagesAsFiles: [filterInput packagesAsFiles]] autorelease];
  
  [taskLock lock];
  treeFilter = [[TreeFilter alloc] initWithFilteredTreeGuide: treeGuide];
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


- (void) disable {
  enabled = NO;

  [treeFilter abort];
}

- (void) enable {
  enabled = YES;
}


- (NSDictionary *)filterProgressInfo {
  NSDictionary  *dict;

  [taskLock lock];
  // The "taskLock" ensures that when treeFilter is not nil, the object will
  // always be valid when it is used (i.e. it won't be deallocated).
  dict = [treeFilter treeFilterProgressInfo];
  [taskLock unlock];
  
  return dict;
}

@end
