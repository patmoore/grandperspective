#import <Cocoa/Cocoa.h>


@class Item;
@class TreeLayoutBuilder;


@interface ItemPathDrawer : NSObject {
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
- (void) drawItemPath:(NSArray*)path tree:(Item*)tree 
           usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder
           bounds:(NSRect)bounds;

@end
