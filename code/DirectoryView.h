#import <Cocoa/Cocoa.h>

@class AsynchronousItemTreeDrawer;
@class ItemPathDrawer;
@class ItemPathBuilder;
@class ItemPathModel;
@class FileItemHashing;

@interface DirectoryView : NSView {

  AsynchronousItemTreeDrawer  *treeDrawer;
  ItemPathDrawer  *pathDrawer;
  ItemPathBuilder  *pathBuilder;
  
  ItemPathModel  *pathModel;
}

- (void) setItemPathModel:(ItemPathModel*)itemPath;
- (ItemPathModel*) itemPathModel;

- (void) setFileItemHashing:(FileItemHashing*)fileItemHashing;
- (FileItemHashing*) fileItemHashing;

@end
