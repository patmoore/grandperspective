#import "FilterTaskInput.h"

#import "TreeHistory.h"


@implementation FilterTaskInput

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithOldContext:filterTest: instead");
}

- (id) initWithOldContext: (TreeContext *)oldContextVal
         filterTest: (NSObject <FileItemTest> *)filterTestVal {
  if (self = [super init]) {
    oldContext = [oldContextVal retain];
    filterTest = [filterTestVal retain];
  }
  return self;
}

- (void) dealloc {
  [oldContext release];
  [filterTest release];
  
  [super dealloc];
}


- (TreeContext *) oldContext {
  return oldContext;
}

- (NSObject <FileItemTest> *) filterTest {
  return filterTest;
}

@end
