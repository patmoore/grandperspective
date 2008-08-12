#import <Cocoa/Cocoa.h>

#import "ObjectPool.h"


/* Maintains a set of mutable arrays for re-use.
 */
@interface MutableArrayPool : ObjectPool {
  int  initialArrayCapacity;
}

- (id) initWithCapacity: (int) maxSize initialArrayCapacity: (int) arraySize;

@end
