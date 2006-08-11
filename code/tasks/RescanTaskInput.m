#import "RescanTaskInput.h"


@implementation RescanTaskInput

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithDirectoryName:filterTest: instead");
}

- (id) initWithDirectoryName: (NSString *)name 
         filterTest: (NSObject <FileItemTest> *)test {
  if (self = [super init]) {
    dirName = [name retain];
    filterTest = [test retain];
  }
  return self;
}

- (void) dealloc {
  [dirName release];
  [filterTest release];
  
  [super dealloc];
}


- (NSString*) directoryName {
  return dirName;
}

- (NSObject <FileItemTest> *) filterTest {
  return filterTest;
}

@end
