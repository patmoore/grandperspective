#import <Cocoa/Cocoa.h>

#import "TaskExecutor.h"

@class ItemTreeDrawer;
@class ItemTreeDrawerSettings;


@interface DrawTaskExecutor : NSObject <TaskExecutor> {
  ItemTreeDrawer  *treeDrawer;
  
  ItemTreeDrawerSettings  *treeDrawerSettings;
  NSLock  *settingsLock;
  
  BOOL  enabled;
}

- (id) init;
- (id) initWithTreeDrawerSettings: (ItemTreeDrawerSettings *)settings;

- (ItemTreeDrawerSettings *) treeDrawerSettings;
- (void) setTreeDrawerSettings: (ItemTreeDrawerSettings *)settings;

@end
