#import "FilterTaskInput.h"

#import "DirectoryItem.h"


@implementation FilterTaskInput

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithItemTree:filterTest: instead");
}

- (id) initWithItemTree: (DirectoryItem *)tree 
         filterTest: (NSObject <FileItemTest> *)test {
  if (self = [super init]) {
    itemTree = [tree retain];
    filterTest = [test retain];
  }
  return self;
}

- (void) dealloc {
  [itemTree release];
  [filterTest release];
  
  [super dealloc];
}


- (DirectoryItem*) itemTree {
  return itemTree;
}

- (NSObject <FileItemTest> *) filterTest {
  return filterTest;
}

@end
