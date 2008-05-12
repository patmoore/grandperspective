#import <Cocoa/Cocoa.h>

#import "TreeLayoutTraverser.h"

@class FileItem;
@class ItemPathModelView;
@class TreeLayoutBuilder;


@interface ItemPathDrawer : NSObject <TreeLayoutTraverser> {
  BOOL          highlightPathEndPoint;

  //---------------------------------------------------------------------------  
  // All variables below are temporary variables only used for drawing the path
  // They are not retained, as they are only used during a single recursive 
  // invocation.
   
  NSArray  *drawPath;
  unsigned int  drawPathIndex;
  
  FileItem  *targetItem;
  
  FileItem  *visibleTree;
  BOOL  insideVisibleTree;
  
  NSBezierPath*  firstBezierPath;
  NSBezierPath*  lastBezierPath;
}

- (void) setHighlightPathEndPoint:(BOOL)option;

/* Draws the part of the path that is visible in the tree. The path may
 * include invisible items, not shown in the tree. However, the path must
 * always include the root of the tree.
 */
- (void) drawVisiblePath: (ItemPathModelView *)pathModelView
           startingAtTree: (FileItem *)treeRoot
           usingLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder
           bounds: (NSRect)bounds;

@end
