#import <Cocoa/Cocoa.h>

#import "TreeLayoutTraverser.h"

@class FileItem;
@class ItemPathModel;
@class TreeLayoutBuilder;

@interface ItemPathBuilder : NSObject <TreeLayoutTraverser> {
  /* All variables below are temporary variables used while building the path.
   * They are not retained, as they are only used during a single recursive 
   * invocation.
   */
   
  FileItem  *foundItem;
  ItemPathModel  *pathModel;
  NSPoint  targetPoint;
  
  FileItem  *visibleTree;
  BOOL  insideVisibleTree;
}

/* Returns the item that is located at the given point (given the tree 
 * drawing settings specified by treeRoot, layoutBuilder and bounds). 
 */
- (FileItem *) itemAtPoint: (NSPoint) point 
                 startingAtTree: (FileItem *)treeRoot
                 usingLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder 
                 bounds: (NSRect) bounds;

/* Returns the item that is located at the given point. Furthermore, if the
 * item is inside the visible tree, the visible path is also extended to end 
 * at this item.
 */
- (FileItem *) itemAtPoint: (NSPoint) point 
                 startingAtTree: (FileItem *)treeRoot
                 usingLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder 
                 bounds: (NSRect) bounds
                 updatePath: (ItemPathModel *)pathModel;
@end
