#import "FilterTaskInput.h"

#import "TreeHistory.h"


@implementation FilterTaskInput

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithOldHistory:filterTest: instead");
}

- (id) initWithOldHistory: (TreeHistory *)oldHistoryVal
         filterTest: (NSObject <FileItemTest> *)filterTestVal {
  if (self = [super init]) {
    oldHistory = [oldHistoryVal retain];
    filterTest = [filterTestVal retain];
  }
  return self;
}

- (void) dealloc {
  [oldHistory release];
  [filterTest release];
  
  [super dealloc];
}


- (TreeHistory *) oldHistory {
  return oldHistory;
}

- (NSObject <FileItemTest> *) filterTest {
  return filterTest;
}

@end
