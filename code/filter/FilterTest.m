#import "FilterTest.h"


@implementation FilterTest

+ (id) filterTestWithName: (NSString *)name 
         fileItemTest: (NSObject <FileItemTest> *)test {
  return [[[FilterTest alloc] initWithName: name fileItemTest: test]
              autorelease];
}

// Overrides designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithName:fileItemTest: instead.");
}

// Designated initialiser.
- (id) initWithName: (NSString *)nameVal
         fileItemTest: (NSObject <FileItemTest> *)testVal {
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

- (NSObject <FileItemTest> *)fileItemTest {
  return test;
}

@end
