#import "FilterTest.h"


@implementation FilterTest

+ (id) filterTestWithName:(NSString *)name {
  return [[[FilterTest alloc] initWithName: name] autorelease];
}


// Overrides designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithName: instead.");
}

- (id) initWithName:(NSString *)nameVal {
  if (self = [super init]) {
    name = [nameVal retain];
    
    // Set default values
    inverted = NO;
    canToggleInverted = YES;
  }

  return self;
}

- (void) dealloc {
  [name release];
  
  [super dealloc];
}


- (NSString *) name {
  return name;
}

- (BOOL) isInverted {
  return inverted;
}

- (void) setCanToggleInverted:(BOOL) flag {
  canToggleInverted = flag;
}

- (BOOL) canToggleInverted {
  return canToggleInverted;
}

- (void) toggleInverted {
  NSAssert([self canToggleInverted], @"Cannot toggle test.");
  inverted = !inverted;
}

@end // @implementation FilterTest
