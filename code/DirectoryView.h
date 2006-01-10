#import <Cocoa/Cocoa.h>

@class TreeLayoutBuilder;
@class ItemTreeDrawer;
@class ItemPathDrawer;
@class ItemPathBuilder;
@class ItemPathModel;
@class FileItemHashing;

@interface DirectoryView : NSView {

  TreeLayoutBuilder  *treeLayoutBuilder;
  ItemTreeDrawer  *treeDrawer;
  ItemPathDrawer  *pathDrawer;
  ItemPathBuilder  *pathBuilder;
  
  ItemPathModel  *pathModel;
}

- (void) setItemPathModel:(ItemPathModel*)itemPath;

- (void) setFileItemHashing:(FileItemHashing*)fileItemHashing;
- (FileItemHashing*) fileItemHashing;

@end
