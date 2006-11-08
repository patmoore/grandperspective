#import <Cocoa/Cocoa.h>

#import "TaskExecutor.h"

@class ItemTreeDrawer;
@class FileItemHashing;
@protocol FileItemTest;


@interface DrawTaskExecutor : NSObject <TaskExecutor> {
  ItemTreeDrawer  *treeDrawer;
  
  FileItemHashing  *fileItemHashing;
  NSColorList  *colorPalette;
  NSObject<FileItemTest>  *fileItemMask;
  
  BOOL  enabled;
}

- (id) initWithTreeDrawer:(ItemTreeDrawer*)treeDrawer;

- (void) setFileItemHashing:(FileItemHashing*)fileItemHashing;
- (FileItemHashing*) fileItemHashing;

- (void) setColorPalette:(NSColorList *)colorPalette;
- (NSColorList*) colorPalette;

- (void) setFileItemMask:(NSObject <FileItemTest>*)fileItemMask;
- (NSObject <FileItemTest> *) fileItemMask;

@end
