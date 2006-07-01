#import "NotItemTest.h"


@implementation NotItemTest

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithSubItemTest: instead.");
}

- (id) initWithSubItemTest:(NSObject<FileItemTest> *)subItemTestVal {
  if (self = [super init]) {
    subItemTest = [subItemTestVal retain];
  }

  return self;
}

- (void) dealloc {
  [subItemTest release];
  
  [super dealloc];
}

- (NSObject <FileItemTest> *) subItemTest {
  return subItemTest;
}

- (BOOL) testFileItem:(FileItem*)item {
  return ! [subItemTest testFileItem:item];
}

@end
