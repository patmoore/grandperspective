#import <Cocoa/Cocoa.h>

@class ItemPathModel;
@class TreeLayoutBuilder;


@interface ItemPathBuilder : NSObject {
  ItemPathModel*  pathModel;

  // Temporary variable, only used while building the path.
  NSPoint   buildTargetPoint;
}

- (id) initWithPathModel:(ItemPathModel*)pathModel;

- (void) buildVisibleItemPathToPoint:(NSPoint)point 
           usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder 
           bounds:(NSRect)bounds;

@end
