#import "ReadTaskExecutor.h"

#import "TreeReader.h"
#import "ReadTaskInput.h"


@implementation ReadTaskExecutor

- (id) init {
  if (self = [super init]) {
    taskLock = [[NSLock alloc] init];
    treeReader = nil;
  }
  return self;
}

- (void) dealloc {
  [taskLock release];
  
  NSAssert(treeReader==nil, @"treeReader should be nil.");
  
  [super dealloc];
}


- (void) prepareToRunTask {
  // Can be ignored because a one-shot object is used for running the task.
}

- (id) runTaskWithInput: (id) input {
  NSAssert( treeReader==nil, @"treeReader already set.");

  ReadTaskInput  *myInput = input;

  [taskLock lock];
  treeReader = [[TreeReader alloc] init];
  [taskLock unlock];

  [treeReader readTreeFromFile: [myInput path]];
  TreeReader  *retVal = [[treeReader retain] autorelease];

  [taskLock lock];
  [treeReader release];
  treeReader = nil;
  [taskLock unlock];

  // Return the TreeReader as next to the tree that is read, its -error and
  // -unboundTests might be of interest as well.
  return retVal;
}

- (void) abortTask {
  [treeReader abort];
}


- (NSDictionary *)progressInfo {
  NSDictionary  *dict;

  [taskLock lock];
  // The "taskLock" ensures that when treeReader is not nil, the object will
  // always be valid when it is used (i.e. it won't be deallocated).
  dict = [treeReader progressInfo];
  [taskLock unlock];
  
  return dict;
}

@end
