#import "ObjectPool.h"


@implementation ObjectPool

/* Creates a pool with an unlimited maximum size.
 */
- (id) init {
  return [self initWithCapacity: INT_MAX];
}

- (id) initWithCapacity: (int) maxSizeVal {
  if (self = [super init]) {
    maxSize = maxSizeVal;
    
    pool = [[NSMutableArray alloc] initWithCapacity: MIN(16, maxSizeVal)];
  }
  
  return self;
}

- (void) dealloc {
  [pool release];
  
  [super dealloc];
}


- (id) borrowObject {
  if ([pool count] > 0) {
    id  obj = [[[pool lastObject] retain] autorelease];
    [pool removeLastObject];

    return obj;
  }
  else {
    return [self createObject];
  }
}

- (void) returnObject: (id) object {
  if ([pool count] < maxSize) {
    [pool addObject: [self resetObject: object]];
  }
}

@end
