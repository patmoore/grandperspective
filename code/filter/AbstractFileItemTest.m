#import "AbstractFileItemTest.h"


@implementation AbstractFileItemTest

// Overrides designated initialiser.
- (id) init {
  if (self = [super init]) {
    name = nil; // Not strictly needed, but better "nil" it explicitly.
  }

  return self;
}

- (void) dealloc {
  [name release];
  
  [super dealloc];
}

- (void) setName:(NSString*)nameVal {
  if (nameVal != name) {
    [name release];
    name = [nameVal retain];
  }
}

- (NSString*) name {
  return name;
}

- (BOOL) testFileItem:(FileItem*)item {
  NSAssert(NO, @"This method must be overridden.");
  return NO;
}

@end
