#import "CompoundItemTest.h"


@implementation CompoundItemTest

- (id) initWithSubItemTests:(NSArray*)subTestsVal {
  if (self = [super initWithName:nameVal]) {
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
