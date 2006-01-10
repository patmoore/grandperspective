#import <Cocoa/Cocoa.h>

#import "TreeLayoutTraverser.h"

@class ItemPathModel;
@class TreeLayoutBuilder;


// TODO: Move TreeLayoutTraverser protocol out of interface, as it's
// only an implementation detail.
@interface ItemPathBuilder : NSObject<TreeLayoutTraverser> {
  ItemPathModel*  pathModel;

  // Temporary variables only used for building the path.
  NSPoint   buildTargetPoint;
}

- (id) initWithPathModel:(ItemPathModel*)pathModel;

- (void) buildVisibleItemPathToPoint:(NSPoint)point 
           usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder 
           bounds:(NSRect)bounds;

@end
