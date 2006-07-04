#import "PeekingEnumerator.h"


@implementation PeekingEnumerator

// Overrides super's designated initialiser.
- (id) init {
  return [self initWithEnumerator:nil]; // nil value -> empty enumerator.
}

- (id) initWithEnumerator:(NSEnumerator*)enumVal {
  if (self = [super init]) {
    enumerator = [enumVal retain];

    nextObject = [enumerator nextObject];
    // Not retaining it, as for efficiency we don't want to auto-release it.
    // Freeing the object while enumeration is ongoing simply a bug and 
    // should never happen.
  }
  return self;
}

- (void) dealloc {
  [enumerator release];
  
  [super dealloc];
}

- (id) nextObject {
  id  returnVal = nextObject;

  nextObject = [enumerator nextObject];
  
  return returnVal;
}

- (id) peekObject {
  return nextObject;
}

@end
