#import <Cocoa/Cocoa.h>

@class Item;
@class ItemTreeDrawer;
@class FileItemHashing;
@class TreeLayoutBuilder;

@interface AsynchronousItemTreeDrawer : NSObject {

  ItemTreeDrawer  *drawer;
  FileItemHashing  *fileItemHashing;  

  NSImage  *image;

  NSConditionLock  *workLock;
  NSLock           *settingsLock;

  // Settings for next drawing task
  Item               *drawItemTree; // Assumed to be immutable
  NSRect             drawInRect;
}

- (id) initWithItemTreeDrawer: (ItemTreeDrawer*)drawer;

// Both "itemTreeRoot" and "layoutBuilder" should be immutable.
- (void) asynchronouslyDrawImageOfItemTree:(Item*)itemTreeRoot 
           inRect:(NSRect)bounds;

- (NSImage*) getImage;
- (void) resetImage;

- (void) setFileItemHashing:(FileItemHashing*)fileItemHashing;
- (FileItemHashing*) fileItemHashing;

- (TreeLayoutBuilder*) treeLayoutBuilder;

@end
