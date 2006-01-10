#import "ItemPathDrawer.h"

#import "Item.h"
#import "TreeLayoutBuilder.h"


@implementation ItemPathDrawer

- (void) setHighlightPathEndPoint:(BOOL)option {
  highlightPathEndPoint = option;
}


- (id) drawItemPath:(NSArray*)path tree:(Item*)tree 
         usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder
         bounds:(NSRect)bounds {

  drawPath = path; // Not retaining it. It's only needed during this method.

  // Align the path with the tree, as the path may contain invisible items
  // not part of the tree.
  drawPathIndex = 0;
  while ([path objectAtIndex:drawPathIndex] != tree) {
    drawPathIndex++;
  }
  
  lastBezierPath = nil;
  [layoutBuilder layoutItemTree:tree inRect:bounds traverser:self];
  
  if (lastBezierPath!=nil) {
    [[NSColor selectedControlColor] set];
      
    if (highlightPathEndPoint) {
      [lastBezierPath setLineWidth:2];
    }
    
    [lastBezierPath stroke];
  }

  drawPath = nil;
}

- (BOOL) descendIntoItem:(Item*)item atRect:(NSRect)rect depth:(int)depth {
  if (drawPathIndex >= [drawPath count] 
        || [drawPath objectAtIndex:drawPathIndex]!=item) {
    return NO;
  }

  drawPathIndex++;

  if (![item isVirtual] && depth > 0) {
    lastBezierPath = [NSBezierPath bezierPathWithRect:rect];
    
    [[NSColor secondarySelectedControlColor] set];

    [lastBezierPath stroke];
  }

  return YES;
}

@end // @implementation ItemPathDrawer