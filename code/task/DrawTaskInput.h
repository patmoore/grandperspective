#import <Cocoa/Cocoa.h>

@class FileItem;
@class TreeLayoutBuilder;

@interface DrawTaskInput : NSObject {
  FileItem  *visibleTree;
  TreeLayoutBuilder  *layoutBuilder;
  NSRect  bounds;
}

- (id) initWithVisibleTree: (FileItem *)visibleTree 
         layoutBuilder: (TreeLayoutBuilder *)layoutBuilder
         bounds: (NSRect) bounds;

- (FileItem *)visibleTree;
- (TreeLayoutBuilder *)layoutBuilder;
- (NSRect) bounds;

@end
