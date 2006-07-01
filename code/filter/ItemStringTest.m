#import "ItemStringTest.h"

@implementation ItemStringTest

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithStringTest: instead.");
}

- (id) initWithStringTest:(NSObject <StringTest>*)stringTestVal {
  if (self = [super init]) {
    stringTest = [stringTestVal retain];
  }
  return self;
}

- (void) dealloc {
  [stringTest release];
  
  [super dealloc];
}

- (NSObject <StringTest>*) stringTest {
  return stringTest;
}

- (BOOL) testFileItem:(FileItem*)item {
  NSAssert(NO, @"This method must be overridden.");
}

@end
