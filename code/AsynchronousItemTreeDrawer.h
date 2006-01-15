#import <Cocoa/Cocoa.h>

@class Item;
@class ItemTreeDrawer;
@class FileItemHashing;
@class TreeLayoutBuilder;

@interface AsynchronousItemTreeDrawer : NSObject {

  ItemTreeDrawer  *drawer;

  NSImage  *image;

  NSConditionLock  *workLock;
  NSLock           *settingsLock;

  // Settings for next drawing task
  FileItemHashing    *drawFileItemHashing;  
  Item               *drawItemTree; // Assumed to be immutable
  TreeLayoutBuilder  *drawLayoutBuilder; // Assumed to be immutable
  NSRect             drawInRect;
}

- (id) initWithItemTreeDrawer: (ItemTreeDrawer*)drawer;

// Both "itemTreeRoot" and "layoutBuilder" should be immutable.
- (void) asynchronouslyDrawImageOfItemTree:(Item*)itemTreeRoot 
           usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder
           inRect:(NSRect)bounds;

- (NSImage*) getImage;
- (void) resetImage;

- (void) setFileItemHashing:(FileItemHashing*)fileItemHashing;

// TODO: Should this be included? It does seem to have much value, as it
// maintained mostly for drawing the next image drawing task.
//- (FileItemHashing*) fileItemHashing;

@end
