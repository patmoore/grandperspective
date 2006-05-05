#import <Cocoa/Cocoa.h>

#import "TaskExecutor.h"

@class ItemTreeDrawer;
@class FileItemHashing;

@interface DrawTaskExecutor : NSObject <TaskExecutor> {
  ItemTreeDrawer  *treeDrawer;
  FileItemHashing  *fileItemHashing;
  
  BOOL  enabled;
}

- (id) initWithTreeDrawer:(ItemTreeDrawer*)treeDrawer;

- (void) setFileItemHashing:(FileItemHashing*)fileItemHashing;
- (FileItemHashing*) fileItemHashing;

@end
