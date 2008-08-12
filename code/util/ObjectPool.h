#import <Cocoa/Cocoa.h>


/* Maintains a set of objects for re-use (mainly to optimize performance). The 
 * objects should be (relatively) expensive to create, and be re-usable, i.e.
 * their state must be reset-able to their initial state.
 *
 * This class should be overridden to implement the methods for creating
 * new objects, and resetting existing ones.
 */
@interface ObjectPool : NSObject {
  int  maxSize;
  NSMutableArray  *pool;
}

/* Creates a pool with an unlimited capacity.
 */
- (id) init;

/* Creates a pool with the given maximum size. It will never hold more than
 * "maxSize" objects.
 */
- (id) initWithCapacity: (int) maxSize;


/* Gets an object. It returns an object from the pool if it is non-empty.
 * Otherwise it creates a new object.
 */
- (id) borrowObject;

/* Returns an object to the pool.
 */
- (void) returnObject: (id) object;

@end


@interface ObjectPool (ProtectedMethods) 

/* Creates a new object that can be lent out by the pool. 
 *
 * Override this to return a properly initialised object of the right class.
 */
- (id) createObject;

/* Resets the object, so that it is ready for re-use.
 */
- (id) resetObject: (id) object;

@end
