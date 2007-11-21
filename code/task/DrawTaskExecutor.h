#import <Cocoa/Cocoa.h>

#import "TaskExecutor.h"

@class DirectoryItem;
@class ItemTreeDrawer;
@class ItemTreeDrawerSettings;


@interface DrawTaskExecutor : NSObject <TaskExecutor> {
  ItemTreeDrawer  *treeDrawer;
  
  ItemTreeDrawerSettings  *treeDrawerSettings;
  NSLock  *settingsLock;
  
  BOOL  enabled;
}

- (id) initWithVolumeTree: (DirectoryItem *)volumeTree;
- (id) initWithVolumeTree: (DirectoryItem *)volumeTree
         treeDrawerSettings: (ItemTreeDrawerSettings *)settings;

- (ItemTreeDrawerSettings *) treeDrawerSettings;
- (void) setTreeDrawerSettings: (ItemTreeDrawerSettings *)settings;

@end
