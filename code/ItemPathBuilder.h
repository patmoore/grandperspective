#import <Cocoa/Cocoa.h>

#import "TreeLayoutTraverser.h"

@class ItemPathModel;
@class TreeLayoutBuilder;

@interface ItemPathBuilder : NSObject <TreeLayoutTraverser> {
  ItemPathModel*  pathModel;

  // Temporary variable, only used while building the path.
  NSPoint   buildTargetPoint;
}

- (id) initWithPathModel:(ItemPathModel*)pathModel;

- (void) buildVisibleItemPathToPoint:(NSPoint)point 
           usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder 
           bounds:(NSRect)bounds;

@end
