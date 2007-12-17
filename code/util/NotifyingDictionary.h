#import <Cocoa/Cocoa.h>


extern NSString  *ObjectAddedEvent;
extern NSString  *ObjectRemovedEvent;
extern NSString  *ObjectUpdatedEvent;
extern NSString  *ObjectRenamedEvent;



@interface NotifyingDictionary : NSObject {

  NSMutableDictionary  *dict;
  NSNotificationCenter  *notificationCenter;

}

- (id) initWithCapacity:(unsigned)capacity;

- (id) initWithCapacity:(unsigned)capacity 
         initialContents:(NSDictionary*)contents;


- (NSNotificationCenter*) notificationCenter; 
- (void) setNotificationCenter:(NSNotificationCenter*)notificationCenter; 


/**
 * Adds the object to the dictionary.
 *
 * Returns "YES" if the operation succeeded, and fires an ObjectAddedEvent
 * notification. The key is available in the userInfo under the "key" string.
 *
 * Returns "NO" if the operation failed (because an object for this key already
 * existed).
 */
- (BOOL) addObject:(id)object forKey:(id)key;

/**
 * Removes the object from the dictionary.
 *
 * Returns "YES" if the operation succeeded, and fires an ObjectRemovedEvent
 * notification. The key is available in the userInfo under the "key" string.
 *
 * Returns "NO" if the operation failed (because no object was stored under
 * the given key.
 */
- (BOOL) removeObjectForKey:(id)key;

/**
 * Updates the object in the dictionary.
 *
 * Returns "YES" if the operation succeeded, and fires an ObjectUpdatedEvent
 * notification. The key is available in the userInfo under the "key" string.
 *
 * Returns "NO" if the operation failed (because no object was stored under
 * the given key.
 *
 * Note: You should also call this method if object reference stored under
 * key did not change, but the object itself did (because it was mutable).
 * Otherwise interested observers will be unaware of the change.
 */
- (BOOL) updateObject:(id)object forKey:(id)key;

/**
 * Moves the object in the dictionary to a different key. It is assumed that
 * the object itself did not change. If it did, you should also invoke
 * updateObject:forKey:.
 *
 * Returns "YES" if the operation succeeded, and fires an ObjectRenamedEvent
 * notification. The old key is available in the userInfo under the "oldkey"
 * string, and the new key similarly under the "newkey" string.
 *
 * Returns "NO" if the operation failed (because no object was stored under
 * the old key, or another object was already stored under the new key).
 */
- (BOOL) moveObjectFromKey:(id)oldKey toKey:(id)newKey;

// Note: you can also call on this object any methods specific to NSDictionary. 

@end
