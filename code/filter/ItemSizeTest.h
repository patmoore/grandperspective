#import <Cocoa/Cocoa.h>

#import "AbstractFileItemTest.h"
#import "Item.h"

/**
 * Item size test.
 */
@interface ItemSizeTest : AbstractFileItemTest {

  ITEM_SIZE  lowerBound;
  ITEM_SIZE  upperBound;

}

- (id) initWithName:(NSString*)name lowerBound:(ITEM_SIZE)lowerBound;

- (id) initWithName:(NSString*)name upperBound:(ITEM_SIZE)upperBound;

- (id) initWithName:(NSString*)name lowerBound:(ITEM_SIZE)lowerBound
                                    upperBound:(ITEM_SIZE)upperBound;
                                    
@end
