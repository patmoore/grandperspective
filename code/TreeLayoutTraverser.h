#import <Cocoa/Cocoa.h>

@class Item;

@protocol TreeLayoutTraverser

- (BOOL) descendIntoItem:(Item*)item atRect:(NSRect)rect depth:(int)depth;  

@end
