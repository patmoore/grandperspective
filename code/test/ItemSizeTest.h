#import <Cocoa/Cocoa.h>

#import "FileItemTest.h"
#import "Item.h"

/**
 * Item size test.
 */
@interface ItemSizeTest : FileItemTest  {

  ITEM_SIZE  lowerBound;
  ITEM_SIZE  upperBound;

}

- (id) initWithLowerBound:(ITEM_SIZE) lowerBound;

- (id) initWithUpperBound:(ITEM_SIZE) upperBound;

- (id) initWithLowerBound:(ITEM_SIZE) lowerBound
               upperBound:(ITEM_SIZE) upperBound;

- (BOOL) hasLowerBound;
- (BOOL) hasUpperBound;

- (ITEM_SIZE) lowerBound;
- (ITEM_SIZE) upperBound;

+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict;

@end
