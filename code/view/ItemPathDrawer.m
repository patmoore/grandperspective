#import "ItemPathDrawer.h"

#import "FileItem.h"
#import "TreeLayoutBuilder.h"
#import "ItemPathModel.h"
#import "ItemPathModelView.h"


@implementation ItemPathDrawer

- (void) setHighlightPathEndPoint: (BOOL) option {
  highlightPathEndPoint = option;
}

- (void) drawVisiblePath: (ItemPathModelView *)pathModelView
           startingAtTree: (FileItem *)treeRoot
           usingLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder
           bounds: (NSRect)bounds {

  NSAssert(drawPath == nil, @"drawPath should be nil.");
  drawPath = [[pathModelView pathModel] itemPath]; 
               // Not retaining it. It is only needed during this method.

  // Align the path with the tree, as the path may contain invisible items
  // not part of the tree.
  drawPathIndex = 0;
  while ([drawPath objectAtIndex: drawPathIndex] != treeRoot) {
    drawPathIndex++;
    
    NSAssert(drawPathIndex < [drawPath count], @"treeRoot not found in path.");
  }
  
  targetItem = [pathModelView selectedFileItemInTree];
  
  NSAssert(visibleTree == nil, @"visibleTree should be nil.");
  visibleTree = [pathModelView visibleTree]; 
  insideVisibleTree = NO;

  prevRect.size.width = -1; // Indicate that it is not yet valid
  outerRect.size.width = -1; // Indicate that it is not yet valid

  
  [layoutBuilder layoutItemTree: treeRoot inRect: bounds traverser: self];
  
  // Draw the end-point rectangle, except when there isn't one, or it is equal
  // to the outermost rectangle and it is not highlighted. This way, there is
  // not unnecessarily a border around the view, which is visually more 
  // appealing, especially in the case where the mouse is outside the view and
  // the selection is actually cleared. When highlighted, the endpoint is 
  // always drawn and clearly visible, even when some/all borders align with 
  // the view's bounds, given that the bounds are not expanded.
  if ( prevRect.size.width > 0 &&
       (! NSEqualRects(prevRect, outerRect) || highlightPathEndPoint) ) {
    [[NSColor selectedControlColor] set];

    NSBezierPath  *path = [NSBezierPath bezierPathWithRect: prevRect];
    
    [path setLineWidth: (highlightPathEndPoint ? 3 : 2)];
    [path stroke];
  }

  drawPath = nil;
  visibleTree = nil;
  targetItem = nil;
}


- (BOOL) descendIntoItem: (Item *)item atRect: (NSRect) rect 
           depth: (int) depth {
  if (outerRect.size.width < 0) {
    outerRect = rect;
  }
           
  if (drawPathIndex >= [drawPath count] 
      || [drawPath objectAtIndex: drawPathIndex] != item) {
    return NO;
  }
  drawPathIndex++;

  if (! [item isVirtual]) {
    if (item==visibleTree) {
      insideVisibleTree = YES;
    }
  
    if (insideVisibleTree) {
      if (prevRect.size.width > 0) {
        // This is not the end-point, so give it the secondary color and 
        // expand it slightly (this way, edges that border the view are not
        // shown, which is visually more attractive; it may happen that the
        // entire bezier path falls outside the view and is invisible, but
        // that is okay, because it is not the endpoint. The endpoint 
        // definitely needs to be shown to provide the user with visual
        // feedback needed to move the focus and to lock and unlock the 
        // selection)
        [[NSColor secondarySelectedControlColor] set];

        NSRect  drawRect = NSMakeRect(prevRect.origin.x - 1,
                                      prevRect.origin.y - 1,
                                      prevRect.size.width + 2,
                                      prevRect.size.height + 2);
        NSBezierPath  *path = [NSBezierPath bezierPathWithRect: drawRect];

        [path setLineWidth: 2];
        [path stroke];
      }

      prevRect = rect;
    }
  }

  return (item != targetItem);
}

- (void) emergedFromItem:(Item*)item {
  if (item == visibleTree) {
    insideVisibleTree = NO;
  }
}

@end // @implementation ItemPathDrawer

