#import "ItemPathDrawer.h"

#import "FileItem.h"
#import "TreeLayoutBuilder.h"
#import "ItemPathModel.h"


@implementation ItemPathDrawer

- (void) setHighlightPathEndPoint: (BOOL) option {
  highlightPathEndPoint = option;
}

- (void) drawVisiblePath: (ItemPathModel *)pathModel
           startingAtTree: (FileItem *)treeRoot
           usingLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder
           bounds: (NSRect)bounds {

  NSAssert(drawPath == nil, @"drawPath should be nil.");
  drawPath = [pathModel itemPathToSelectedFileItem]; 
               // Not retaining it. It is only needed during this method.

  // Align the path with the tree, as the path may contain invisible items
  // not part of the tree.
  drawPathIndex = 0;
  while ([drawPath objectAtIndex: drawPathIndex] != treeRoot) {
    drawPathIndex++;
    
    NSAssert(drawPathIndex < [drawPath count], @"treeRoot not found in path.");
  }
  
  insideVisibleTree = NO;
  NSAssert(visibleTree == nil, @"visibleTree should be nil.");
  visibleTree = [pathModel visibleTree]; 

  firstBezierPath = nil;
  lastBezierPath = nil;
  
  [layoutBuilder layoutItemTree: treeRoot inRect: bounds traverser: self];
  
  if (lastBezierPath != nil) {
    [[NSColor selectedControlColor] set];
      
    [lastBezierPath setLineWidth: (highlightPathEndPoint ? 3 : 2)];

    if ((firstBezierPath != lastBezierPath) || highlightPathEndPoint) {
      // Only draw the last path component if it is not the only one, or if
      // it should be highlighted. Otherwise, the item at the end of the path
      // is not considered as selected, so should not be drawn either. 
      [lastBezierPath stroke];
     }
  }

  drawPath = nil;
  visibleTree = nil;
}


- (BOOL) descendIntoItem: (Item *)item atRect: (NSRect) rect 
           depth: (int) depth {
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
      if (lastBezierPath != nil) {
        // This is not the end-point, so give it the secondary color.
        //   (Also, should this be the outer rectangle, as it is not the
        //    end-point, it may also be drawn).    
        [[NSColor secondarySelectedControlColor] set];
        [lastBezierPath setLineWidth: 2];
        [lastBezierPath stroke];
      }
  
      lastBezierPath = [NSBezierPath bezierPathWithRect: rect];

      if (firstBezierPath == nil) {
        firstBezierPath = lastBezierPath;
      }
    }
  }

  return YES;
}

- (void) emergedFromItem:(Item*)item {
  if (item == visibleTree) {
    insideVisibleTree = NO;
  }
}

@end // @implementation ItemPathDrawer

