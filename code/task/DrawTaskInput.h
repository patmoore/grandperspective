#import <Cocoa/Cocoa.h>

@class FileItem;
@class TreeLayoutBuilder;

@interface DrawTaskInput : NSObject {
  FileItem  *visibleTree;
  FileItem  *treeInView;
  TreeLayoutBuilder  *layoutBuilder;
  NSRect  bounds;
}

- (id) initWithVisibleTree: (FileItem *)visibleTree
         treeInView: (FileItem *)treeInView 
         layoutBuilder: (TreeLayoutBuilder *)layoutBuilder
         bounds: (NSRect) bounds;

- (FileItem *)visibleTree;
- (FileItem *)treeInView;
- (TreeLayoutBuilder *)layoutBuilder;
- (NSRect) bounds;

@end
