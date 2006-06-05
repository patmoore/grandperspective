#import "CompoundItemTest.h"


@implementation CompoundItemTest

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithSubItemTests: instead.");
}

- (id) initWithSubItemTests:(NSArray*)subTestsVal {
  if (self = [super init]) {
    // Make the array immutable
    subTests = [[NSArray alloc] initWithArray:subTestsVal];
  }
  
  return self;
}

- (void) dealloc {
  [subTests release];
  
  [super dealloc];
}

- (NSArray*) subItemTests {
  return subTests;
}

@end
