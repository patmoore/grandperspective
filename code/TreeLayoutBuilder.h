#import <Cocoa/Cocoa.h>

@class Item;
@protocol TreeLayoutTraverser;

@interface TreeLayoutBuilder : NSObject {
}

- (void) layoutItemTree:(Item*)itemTreeRoot inRect:(NSRect)bounds
           traverser:(id <TreeLayoutTraverser>)traverser;

@end
