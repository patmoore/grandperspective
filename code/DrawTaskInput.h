#import <Cocoa/Cocoa.h>

@class Item;

@interface DrawTaskInput : NSObject {
  Item  *itemTree;
  NSRect  bounds;
}

- (id) initWithItemTree:(Item*)itemTree bounds:(NSRect)bounds;

- (Item*) itemTree;
- (NSRect) bounds;

@end
