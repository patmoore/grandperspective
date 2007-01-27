#import "RescanTaskInput.h"


@implementation RescanTaskInput

// Overrides designated initialiser
- (id) initWithDirectoryName: (NSString *)name 
         fileSizeType: (int)fileSizeTypeVal {
  NSAssert(NO, @"Use initWithDirectoryName:fileSizeType:filterTest: instead");
}

- (id) initWithDirectoryName: (NSString *)name 
         fileSizeType: (int)fileSizeTypeVal
         filterTest: (NSObject <FileItemTest> *)test {
  if (self = [super initWithDirectoryName: name 
                      fileSizeType: fileSizeTypeVal]) {
    filterTest = [test retain];
  }
  return self;
}

- (void) dealloc {
  [filterTest release];
  
  [super dealloc];
}


- (NSObject <FileItemTest> *) filterTest {
  return filterTest;
}

@end
