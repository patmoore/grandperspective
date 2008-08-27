#import "ReadTaskExecutor.h"

#import "TreeReader.h"
#import "ReadTaskInput.h"


@implementation ReadTaskExecutor

- (id) init {
  if (self = [super init]) {
    taskLock = [[NSLock init] alloc];
    treeReader = nil;

    enabled = YES;    
  }
  return self;
}

- (void) dealloc {
  [taskLock release];
  
  NSAssert(treeReader==nil, @"treeReader should be nil.");
  
  [super dealloc];
}


- (id) runTaskWithInput: (id) input {
  if (!enabled) {
    return nil;
  }
  
  NSAssert( treeReader==nil, @"treeReader already set.");

  ReadTaskInput  *myInput = input;

  [taskLock lock];
  treeReader = [[TreeReader alloc] init];
  [taskLock unlock];

  id  result = [treeReader readTreeFromFile: [myInput path]];
  if (result == nil) {
    result = [[[treeReader error] retain] autorelease]; 
      // Will return nil when task was aborted
  }

  [taskLock lock];
  [treeReader release];
  treeReader = nil;
  [taskLock unlock];

  return result;
}


- (void) disable {
  enabled = NO;

  [treeReader abort];
}

- (void) enable {
  enabled = YES;
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
