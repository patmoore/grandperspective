#import <Cocoa/Cocoa.h>

#define ITEM_SIZE  unsigned long long


@interface Item : NSObject {
  ITEM_SIZE  size;
}


/* Determines if a dedicated memory zone for allocating item objects. If "flag"
 * equals YES, all newly created items will be allocated in a dedicated zone.
 */
+ (void) useDedicatedZone: (BOOL) flag;

/* Returns the memory zone in which newly created items are allocated. It
 * returns "nil" if the default zone is used.
 */
+ (NSZone *) zone;

- (id) initWithItemSize:(ITEM_SIZE)size;

- (ITEM_SIZE) itemSize;

// An item is virtual if it is not a file item (i.e. a file or directory).
- (BOOL) isVirtual;

@end
