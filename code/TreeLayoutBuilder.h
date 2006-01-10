#import <Cocoa/Cocoa.h>

@class Item;
@protocol TreeLayoutTraverser;

@interface TreeLayoutBuilder : NSObject {
  // TODO: Why not "id <TreeLayoutTraverser>"?
  id  layoutLimits;
}

- (void) setLayoutLimits:(id <TreeLayoutTraverser>)layoutLimits;

- (void) layoutItemTree:(Item*)itemTreeRoot inRect:(NSRect)bounds
           traverser:(id <TreeLayoutTraverser>)traverser;

@end
