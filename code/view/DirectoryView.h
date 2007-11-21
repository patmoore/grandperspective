#import <Cocoa/Cocoa.h>

@class AsynchronousTaskManager;
@class TreeLayoutBuilder;
@class ItemTreeDrawerSettings;
@class ItemPathDrawer;
@class ItemPathBuilder;
@class ItemPathModel;

@interface DirectoryView : NSView {
  AsynchronousTaskManager  *drawTaskManager;

  TreeLayoutBuilder  *layoutBuilder;
  BOOL  showEntireVolume;
  
  ItemPathDrawer  *pathDrawer;
  ItemPathBuilder  *pathBuilder;
  
  ItemPathModel  *pathModel;
  
  NSImage  *treeImage;  
}

// Initialises the instance-specific state after the view has been restored
// from the nib file (which invokes the generic initWithFrame: method).
- (void) postInitWithItemPathModel: (ItemPathModel *)pathModelVal;

- (ItemPathModel*) itemPathModel;

- (void) setShowEntireVolume: (BOOL) flag;
- (BOOL) showEntireVolume;

- (ItemTreeDrawerSettings *) treeDrawerSettings;
- (void) setTreeDrawerSettings: (ItemTreeDrawerSettings *)settings;

- (TreeLayoutBuilder*) layoutBuilder;

@end
