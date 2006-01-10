#import <Cocoa/Cocoa.h>


#import "TreeLayoutTraverser.h"

@class Item;
@class TreeLayoutBuilder;


// TODO: Move TreeLayoutTraverser protocol out of interface, as it's
// only an implementation detail.
@interface ItemPathDrawer : NSObject<TreeLayoutTraverser> {
  BOOL          highlightPathEndPoint;

  // Temporary variables only used for drawing the path
  NSArray*       drawPath;
  unsigned int   drawPathIndex;
  NSBezierPath*  lastBezierPath;
}

- (void) setHighlightPathEndPoint:(BOOL)option;

// Draws the part of the path that is visible in the tree. The path may
// include invisible items, not shown in the tree. However, the path must
// always include the root of the tree.
- (id) drawItemPath:(NSArray*)path tree:(Item*)tree 
         usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder
         bounds:(NSRect)bounds;

@end
