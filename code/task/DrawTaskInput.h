#import <Cocoa/Cocoa.h>

@class FileItem;
@class TreeLayoutBuilder;

@interface DrawTaskInput : NSObject {
  FileItem  *itemTree;
  TreeLayoutBuilder  *layoutBuilder;
  NSRect  bounds;
}

- (id) initWithItemSubTree: (FileItem *)itemTree 
         layoutBuilder: (TreeLayoutBuilder *)layoutBuilder
         bounds: (NSRect) bounds;

- (FileItem*) itemSubTree;
- (TreeLayoutBuilder *) treeLayoutBuilder;
- (NSRect) bounds;

@end
