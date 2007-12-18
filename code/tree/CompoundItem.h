#import <Cocoa/Cocoa.h>

#import "Item.h"

@interface CompoundItem : Item {
  Item*  first;
  Item*  second;
}

/* Both items must be non-nil.
 */
- (id) initWithFirst:(Item*)first second:(Item*)second;

- (Item*) getFirst;

- (Item*) getSecond;


/* Replaces the first item. The item must have the same size as the original
 * one (otherwise the resulting tree would be incorrect). 
 *
 * Note: It is the responsibility of the sender to ensure that this method is
 * only called when the tree can be modified (e.g. it should not be traversed
 * in another thread). Furthermore, the sender is responsible for notifying 
 * objects affected by the change.
 */
- (void) replaceFirst: (Item *)newItem;

// Replaces the second item. See also -replaceFirst.
- (void) replaceSecond: (Item *)newItem;

/* Can handle case where either one or both are nil:
 * If both are nil, it returns nil
 * If one item is nil, it returns the other item
 * Otherwise it returns a CompoundItem  containing both.
 */
+ (Item*) compoundItemWithFirst:(Item*)first second:(Item*)second;

@end
