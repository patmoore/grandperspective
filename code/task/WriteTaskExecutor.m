#import "WriteTaskExecutor.h"

#import "TreeWriter.h"
#import "WriteTaskInput.h"


@implementation WriteTaskExecutor

- (id) init {
  if (self = [super init]) {
    taskLock = [[NSLock alloc] init];
    treeWriter = nil;
  }
  return self;
}

- (void) dealloc {
  [taskLock release];
  
  NSAssert(treeWriter==nil, @"treeWriter should be nil.");
  
  [super dealloc];
}


- (id) runTaskWithInput: (id) input {
  NSAssert( treeWriter==nil, @"treeWriter already set.");

  WriteTaskInput  *myInput = input;

  [taskLock lock];
  treeWriter = [[TreeWriter alloc] init];
  [taskLock unlock];

  id  result = nil;
  if ([treeWriter writeTree: [myInput treeContext] toFile: [myInput path]]) {
    result = SuccessfulVoidResult;
  }
  else {
    result = [[[treeWriter error] retain] autorelease]; 
      // Will return nil when task was aborted
  }

  [taskLock lock];
  [treeWriter release];
  treeWriter = nil;
  [taskLock unlock];

  return result;
}


- (void) abortTask {
  [treeWriter abort];
}


- (NSDictionary *)progressInfo {
  NSDictionary  *dict;

  [taskLock lock];
  // The "taskLock" ensures that when treeWriter is not nil, the object will
  // always be valid when it is used (i.e. it won't be deallocated).
  dict = [treeWriter progressInfo];
  [taskLock unlock];
  
  return dict;
}

@end
