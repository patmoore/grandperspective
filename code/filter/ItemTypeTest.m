#import "ItemTypeTest.h"


@implementation ItemTypeTest

// Overrides designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithTestForPlainFile instead.");
}

- (id) initWithTestForPlainFile:(BOOL)plainFileFlag {
  if (self = [super init]) {
    testForPlainFile = plainFileFlag;    
  }
  
  return self;
}

- (BOOL) testsForPlainFile {
  return testForPlainFile;
}

- (BOOL) testFileItem:(FileItem*)item {
  return [item isPlainFile] == testForPlainFile;
}

- (NSString*) description {
  return (testForPlainFile ? @"item is a file" : @"item is a folder");
}

@end
