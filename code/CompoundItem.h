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

/* Can handle case where either one or both are nil:
 * If both are nil, it returns nil
 * If one item is nil, it returns the other item
 * Otherwise it returns a CompoundItem  containing both.
 */
+ (Item*) compoundItemWithFirst:(Item*)first second:(Item*)second;

@end
