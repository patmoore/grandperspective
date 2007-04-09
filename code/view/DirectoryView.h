#import <Cocoa/Cocoa.h>

@class AsynchronousTaskManager;
@class TreeLayoutBuilder;
@class ConstrainedTreeLayoutBuilder;
@class ItemTreeDrawerSettings;
@class ItemPathDrawer;
@class ItemPathBuilder;
@class ItemPathModel;

@interface DirectoryView : NSView {
  AsynchronousTaskManager  *drawTaskManager;

  TreeLayoutBuilder  *fullLayoutBuilder;
  ConstrainedTreeLayoutBuilder  *freeSpaceLayoutBuilder;
  BOOL  showFreeSpace;
  
  ItemPathDrawer  *pathDrawer;
  ItemPathBuilder  *pathBuilder;
  
  ItemPathModel  *pathModel;
  
  NSImage  *treeImage;  
}

// Initialises the instance-specific state after the view has been restored
// from the nib file (which invokes the generic initWithFrame: method).
- (void) postInitWithFreeSpace: (unsigned long long) freeSpace
           itemPathModel: (ItemPathModel *)pathModelVal;

// TODO: Check if it is needed
- (unsigned long long) freeSpace;

- (ItemPathModel*) itemPathModel;

- (void) setShowFreeSpace: (BOOL) flag;
- (BOOL) showFreeSpace;

- (ItemTreeDrawerSettings *) treeDrawerSettings;
- (void) setTreeDrawerSettings: (ItemTreeDrawerSettings *)settings;

- (TreeLayoutBuilder*) activeLayoutBuilder;

@end
