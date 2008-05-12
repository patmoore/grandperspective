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

  firstBezierPath = nil;
  lastBezierPath = nil;
  
  [layoutBuilder layoutItemTree: treeRoot inRect: bounds traverser: self];
  
  if (lastBezierPath != nil) {
    [[NSColor selectedControlColor] set];
    [lastBezierPath setLineWidth: (highlightPathEndPoint ? 3 : 2)];
    [lastBezierPath stroke];
  }

  drawPath = nil;
  visibleTree = nil;
  targetItem = nil;
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

  return (item != targetItem);
}

- (void) emergedFromItem:(Item*)item {
  if (item == visibleTree) {
    insideVisibleTree = NO;
  }
}

@end // @implementation ItemPathDrawer

