#import <Cocoa/Cocoa.h>

@class FileItem;

@interface DrawTaskInput : NSObject {
  FileItem  *itemTree;
  NSRect  bounds;
}

- (id) initWithItemSubTree: (FileItem *)itemTree bounds: (NSRect) bounds;

- (FileItem*) itemSubTree;
- (NSRect) bounds;

@end
