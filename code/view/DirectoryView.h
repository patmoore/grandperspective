#import <Cocoa/Cocoa.h>

@class AsynchronousTaskManager;
@class TreeLayoutBuilder;
@class ItemTreeDrawerSettings;
@class ItemPathDrawer;
@class ItemPathBuilder;
@class ItemPathModel;

@interface DirectoryView : NSView {
  AsynchronousTaskManager  *drawTaskManager;

  // Even though layout builder could also be considered part of the
  // itemTreeDrawerSettings, it is maintained here, as it is also needed by
  // the pathDrawer, and other objects.
  TreeLayoutBuilder  *layoutBuilder;
  
  ItemPathDrawer  *pathDrawer;
  ItemPathBuilder  *pathBuilder;
  
  ItemPathModel  *pathModel;
  
  NSImage  *treeImage;  
}

// Initialises the instance-specific state after the view has been restored
// from the nib file (which invokes the generic initWithFrame: method).
- (void) postInitWithPathModel: (ItemPathModel *)pathModelVal;

- (ItemPathModel*) itemPathModel;

- (ItemTreeDrawerSettings *) treeDrawerSettings;
- (void) setTreeDrawerSettings: (ItemTreeDrawerSettings *)settings;

- (TreeLayoutBuilder*) layoutBuilder;

@end
