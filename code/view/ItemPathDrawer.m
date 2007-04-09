#import "ItemPathDrawer.h"

#import "Item.h"
#import "TreeLayoutBuilder.h"


@implementation ItemPathDrawer

- (void) setHighlightPathEndPoint: (BOOL) option {
  highlightPathEndPoint = option;
}

 
- (void) drawItemPath: (NSArray *)path
           tree: (Item *)tree
           usingLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder
           bounds: (NSRect) bounds {

  drawPath = path; // Not retaining it. It's only needed during this method.

  // Align the path with the tree, as the path may contain invisible items
  // not part of the tree.
  drawPathIndex = 0;
  while ([path objectAtIndex: drawPathIndex] != tree) {
    drawPathIndex++;
  }
  
  firstBezierPath = nil;
  lastBezierPath = nil;
  
  [layoutBuilder layoutItemTree: tree inRect: bounds traverser: self];
  
  if (lastBezierPath != nil) {
    [[NSColor selectedControlColor] set];
      
    if (highlightPathEndPoint) {
      [lastBezierPath setLineWidth: 2];
    }

    if ((firstBezierPath != lastBezierPath) || highlightPathEndPoint) {
      // Only draw the last path component if it is not the only one, or if
      // it should be highlighted. Otherwise, the item at the end of the path
      // is not considered as selected, so should not be drawn either. 
      [lastBezierPath stroke];
     }
  }

  drawPath = nil;
}


- (BOOL) descendIntoItem: (Item *)item atRect: (NSRect) rect 
           depth: (int) depth {
  if (drawPathIndex >= [drawPath count] 
        || [drawPath objectAtIndex: drawPathIndex] != item) {
    return NO;
  }

  drawPathIndex++;

  if (! [item isVirtual]) {
    if (lastBezierPath != nil) {
      // This is not the end-point, so give it the secondary color.
      //   (Also, should this be the outer rectangle, as it is not the
      //    end-point, it may also be drawn).    
      [[NSColor secondarySelectedControlColor] set];
      [lastBezierPath stroke];
    }
  
    lastBezierPath = [NSBezierPath bezierPathWithRect: rect];

    if (firstBezierPath == nil) {
      firstBezierPath = lastBezierPath;
    }
  }

  return YES;
}

@end // @implementation ItemPathDrawer

