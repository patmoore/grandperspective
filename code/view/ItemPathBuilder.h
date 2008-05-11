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
  
  BOOL  descendIntoPackages;  
  
  FileItem  *visibleTree;
  BOOL  insideVisibleTree;
  BOOL  wasInsideVisibleTree;
}

/* Returns the item that is located at the given point (given the tree 
 * drawing settings specified by treeRoot, layoutBuilder and bounds). 
 */
- (FileItem *) selectItemAtPoint: (NSPoint) point 
                 startingAtTree: (FileItem *)treeRoot
                 usingLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder 
                 bounds: (NSRect) bounds
                 descendIntoPackages: (BOOL) descendIntoPackages;

/* Returns the item that is located at the given point. Furthermore, if the
 * item is inside the visible tree, the visible path is also updated to point 
 * to the selected item.
 */
- (FileItem *) selectItemAtPoint: (NSPoint) point 
                 startingAtTree: (FileItem *)treeRoot
                 usingLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder 
                 bounds: (NSRect) bounds
                 descendIntoPackages: (BOOL) descendIntoPackages
                 updatePath: (ItemPathModel *)pathModel;
@end
