#import "FilterTestRef.h"


@implementation FilterTestRef

+ (id) filterTestWithName:(NSString *)name {
  return [[[FilterTestRef alloc] initWithName: name] autorelease];
}


// Overrides designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithName: instead.");
}

- (id) initWithName:(NSString *)nameVal {
  return [self initWithName: nameVal inverted: NO];
}

- (id) initWithName:(NSString *)nameVal inverted:(BOOL) invertedVal {
  if (self = [super init]) {
    name = [nameVal retain];
    inverted = invertedVal;

    // Set default values
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

@end // @implementation FilterTestRef
