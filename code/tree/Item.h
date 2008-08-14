#import <Cocoa/Cocoa.h>

#define ITEM_SIZE  unsigned long long


@interface Item : NSObject {
  ITEM_SIZE  size;
}


/* Returns a memory zone that is intended solely for storing Item trees.
 *
 * Using this dedicated zone can be beneficial because the life-span of all 
 * objects in a tree is identical, and typically long-lived. As short-lived, 
 * temporary objects needed during tree construction are created in the default
 * zone, they won't be mixed in memory. This should result in far less (hardly 
 * any) memory fragmentation, which means that memory is used more efficiently.
 */
+ (NSZone *) dedicatedZone;

- (id) initWithItemSize:(ITEM_SIZE)size;

- (ITEM_SIZE) itemSize;

// An item is virtual if it is not a file item (i.e. a file or directory).
- (BOOL) isVirtual;

@end
