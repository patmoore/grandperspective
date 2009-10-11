#import "FilterTest.h"


@implementation FilterTest

+ (id) filterTestWithName:(NSString *)name fileItemTest:(FileItemTest *)test {
  return [[[FilterTest alloc] initWithName: name fileItemTest: test]
              autorelease];
}

// Overrides designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithName:fileItemTest: instead.");
}

// Designated initialiser.
- (id) initWithName:(NSString *)nameVal fileItemTest:(FileItemTest *)testVal {
  if (self = [super init]) {
    name = [nameVal retain];
    test = [testVal retain];
  }
  return self;
}

- (void) dealloc {
  [name release];
  [test release];
  
  [super dealloc];
}


- (NSString *)name {
  return name;
}

- (FileItemTest *)fileItemTest {
  return test;
}

@end
