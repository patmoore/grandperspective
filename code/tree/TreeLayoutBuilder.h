#import <Cocoa/Cocoa.h>

@class Item;
@protocol TreeLayoutTraverser;

// Layout builders are immutable.
@interface TreeLayoutBuilder : NSObject {
}

- (void) layoutItemTree:(Item *)itemTreeRoot inRect:(NSRect)bounds
           traverser:(NSObject <TreeLayoutTraverser> *)traverser;

@end
