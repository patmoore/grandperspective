#import <Cocoa/Cocoa.h>

#import "TaskExecutor.h"

@class DirectoryItem;
@class TreeDrawer;
@class TreeDrawerSettings;
@class TreeContext;


@interface DrawTaskExecutor : NSObject <TaskExecutor> {
  TreeContext  *treeContext;

  TreeDrawer  *treeDrawer;
  
  TreeDrawerSettings  *treeDrawerSettings;
  NSLock  *settingsLock;
  
  BOOL  enabled;
}

- (id) initWithTreeContext: (TreeContext *)treeContext;
- (id) initWithTreeContext: (TreeContext *)treeContext 
         drawingSettings: (TreeDrawerSettings *)settings;

- (TreeDrawerSettings *) treeDrawerSettings;
- (void) setTreeDrawerSettings: (TreeDrawerSettings *)settings;

@end
