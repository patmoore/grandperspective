#import "ScanTaskInput.h"


@implementation ScanTaskInput

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithDirectoryName:fileSizeMeasure:filterTest instead");
}

- (id) initWithDirectoryName: (NSString *)dirNameVal 
         fileSizeMeasure: (NSString *)fileSizeMeasureVal
         filterTest: (NSObject <FileItemTest> *)filterTestVal {
  if (self = [super init]) {
    dirName = [dirNameVal retain];
    fileSizeMeasure = [fileSizeMeasureVal retain];
    filterTest = [filterTestVal retain];
  }
  return self;
}

- (void) dealloc {
  [dirName release];
  [fileSizeMeasure release];
  [filterTest release];
  
  [super dealloc];
}


- (NSString *) directoryName {
  return dirName;
}

- (NSString *) fileSizeMeasure {
  return fileSizeMeasure;
}

- (NSObject <FileItemTest> *) filterTest {
  return filterTest;
}

@end
