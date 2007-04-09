#import <Cocoa/Cocoa.h>

@class AsynchronousTaskManager;
@class TreeLayoutBuilder;
@class ItemPathDrawer;
@class ItemPathBuilder;
@class ItemPathModel;
@class FileItemHashing;
@protocol FileItemTest;

@interface DirectoryView : NSView {
  AsynchronousTaskManager  *drawTaskManager;

  TreeLayoutBuilder  *treeLayoutBuilder;
  ItemPathDrawer  *pathDrawer;
  ItemPathBuilder  *pathBuilder;
  
  ItemPathModel  *pathModel;
  
  NSImage  *treeImage;  
}

// Initialises the instance-specific state after the view has been restored
// from the nib file (which invokes the generic initWithFrame: method).
- (void) postInitWithFreeSpace: (unsigned long long) freeSpace
           itemPathModel: (ItemPathModel *)pathModelVal;

- (unsigned long long) freeSpace;

- (ItemPathModel*) itemPathModel;

- (void) setShowFreeSpace: (BOOL) flag;
- (BOOL) showFreeSpace;

- (void) setColorMapping:(FileItemHashing *)colorMapping;
- (FileItemHashing*) colorMapping;

- (void) setColorPalette:(NSColorList *)colorPalette;
- (NSColorList*) colorPalette;

- (void) setFileItemMask:(NSObject <FileItemTest>*)fileItemMask;
- (NSObject <FileItemTest> *) fileItemMask;

@end
