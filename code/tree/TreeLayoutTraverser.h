#import <Cocoa/Cocoa.h>

@class Item;


/* Protocol implemented by objects that need to "traverse" the tree-map layout
 * built by the TreeLayoutBuilder. TreeLayoutTraversers can dynamically
 * indicate which parts of the layout need to be built.
 */
@protocol TreeLayoutTraverser

/* Called to signal that the given item is layed out at the given rectangle.
 *
 * The depth is the number of sub-directories between the given item and the 
 * part of the tree where the traversal started (notnecessarily the root of 
 * the tree). It is passed as a matter of convenience, for traversers that 
 * like to use it.
 *
 * The callee should return YES iff traversal should continue within the given
 * rectangle.
 */
- (BOOL) descendIntoItem: (Item *)item atRect: (NSRect) rect depth: (int) depth;

/* Called to signal that traversal within the given item has been completed.
 * It is only called for item's for which the earlier invocation of 
 * descendIntoItem:atRect:depth returned YES.
 */
- (void) emergedFromItem: (Item *)item;

@end
