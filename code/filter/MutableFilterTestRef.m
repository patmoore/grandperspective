#import "MutableFilterTestRef.h"


@implementation MutableFilterTestRef

// Override designated initialiser
- (id) initWithName:(NSString *)nameVal inverted:(BOOL) invertedVal {
  if (self = [super initWithName: nameVal inverted: invertedVal]) {
    // Set default value
    canToggleInverted = YES;
  }

  return self;
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

@end // @implementation MutableFilterTestRef
