#import <Cocoa/Cocoa.h>

#import "TaskExecutor.h"

@class DirectoryItem;
@class ItemTreeDrawer;
@class ItemTreeDrawerSettings;
@class TreeContext;


@interface DrawTaskExecutor : NSObject <TaskExecutor> {
  TreeContext  *treeContext;

  ItemTreeDrawer  *treeDrawer;
  
  ItemTreeDrawerSettings  *treeDrawerSettings;
  NSLock  *settingsLock;
  
  BOOL  enabled;
}

- (id) initWithTreeContext: (TreeContext *)treeContext;
- (id) initWithTreeContext: (TreeContext *)treeContext 
         drawingSettings: (ItemTreeDrawerSettings *)settings;

- (ItemTreeDrawerSettings *) treeDrawerSettings;
- (void) setTreeDrawerSettings: (ItemTreeDrawerSettings *)settings;

@end
