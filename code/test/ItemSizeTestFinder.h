#import <Cocoa/Cocoa.h>

#import "BasicFileItemTestVisitor.h"


/* Simple visitor that can be used to check if a (compound) FileItemTest 
 * contains an ItemSizeTest as one of its subtests.
 */
@interface ItemSizeTestFinder : BasicFileItemTestVisitor {
  BOOL  itemSizeTestFound;
}

/* Resets the finder so that it can be used on a new test.
 */
- (void) reset;

/* Returns YES if an ItemSizeTest has been encountered. It should be called
 * after the finder has "visited" the FileItemTest for which it should 
 * determine whether or not the test includes an ItemSizeTest.
 */
- (BOOL) itemSizeTestFound;

@end
