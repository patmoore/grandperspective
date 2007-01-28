#import "RescanTaskInput.h"


@implementation RescanTaskInput

// Overrides designated initialiser
- (id) initWithDirectoryName: (NSString *)name 
         fileSizeMeasure: (int) measure {
  NSAssert
    (NO, @"Use initWithDirectoryName:fileSizeMeasure:filterTest: instead");
}

- (id) initWithDirectoryName: (NSString *)name 
         fileSizeMeasure: (int) measure
         filterTest: (NSObject <FileItemTest> *)test {
  if (self = [super initWithDirectoryName: name fileSizeMeasure: measure]) {
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
