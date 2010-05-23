#import <Cocoa/Cocoa.h>

#define ITEM_SIZE  unsigned long long
#define FILE_COUNT  unsigned long long


@interface Item : NSObject {
  ITEM_SIZE  size;
}


/* Returns a memory zone that is intended for storing an Item tree. Depending
 * on the preference settings, it can be 1) the default zone, 2) a dedicated
 * zone for all trees, 3) a dedicated private zone for the given tree.
 *
 * Using a dedicated zone can be beneficial because the life-span of all 
 * objects in a tree is identical, and typically long-lived. As short-lived, 
 * temporary objects needed during tree construction are created in the default
 * zone, they won't be mixed in memory. This should result in far less (hardly 
 * any) memory fragmentation, which means that memory is used more efficiently.
 */
+ (NSZone *)zoneForTree;

/* Indicates if the zone should be disposed of when the tree is deallocated.
 * This is the case when the tree used a dedicated, private zone.
 */
+ (BOOL) disposeZoneAfterUse:(NSZone *)zone;

- (id) initWithItemSize:(ITEM_SIZE)size;

- (ITEM_SIZE) itemSize;
- (FILE_COUNT) numFiles;

// An item is virtual if it is not a file item (i.e. a file or directory).
- (BOOL) isVirtual;

@end
