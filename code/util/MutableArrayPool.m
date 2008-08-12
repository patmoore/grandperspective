#import "MutableArrayPool.h"


@implementation MutableArrayPool

// Overrides designated initialiser.
- (id) initWithCapacity: (int) maxSizeVal {
  return [self initWithCapacity: maxSizeVal initialArrayCapacity: 16];
}

- (id) initWithCapacity: (int) maxSizeVal 
         initialArrayCapacity: (int) initialArraySize {
  if (self = [super initWithCapacity: maxSizeVal]) {
    initialArrayCapacity = initialArraySize;
  }
  
  return self;
}


- (id) createObject {
  return [NSMutableArray arrayWithCapacity: initialArrayCapacity];
}

- (id) resetObject: (id) object {
  [object removeAllObjects];
  return object;
}

@end
