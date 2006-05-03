#import <Cocoa/Cocoa.h>

@class Item;
@class TreeLayoutBuilder;
@class FileItemHashing;
@class ColorPalette;

@interface ItemTreeDrawer : NSObject {

  FileItemHashing  *fileItemHashing;
  TreeLayoutBuilder  *layoutBuilder;

  // Only set when it has not yet been loaded into the gradient array.
  ColorPalette  *colorPalette;
  //NSArray  *gradientColors;
  UInt32  *gradientColors;
  int  numGradientColors;

  NSBitmapImageRep  *drawBitmap;
  BOOL  abort;
}

- (id) initWithFileItemHashing:(FileItemHashing*)fileItemHashing;

- (id) initWithFileItemHashing: (FileItemHashing*)fileItemHashing
         colorPalette: (ColorPalette*)colorPalette
         layoutBuilder: (TreeLayoutBuilder*)layoutBuilder;

- (void) setTreeLayoutBuilder: (TreeLayoutBuilder*)layoutBuilder;
- (TreeLayoutBuilder*) treeLayoutBuilder;

- (void) setFileItemHashing:(FileItemHashing*)fileItemHashing;
- (FileItemHashing*) fileItemHashing;

- (void) setColorPalette:(ColorPalette*)colorPalette;

// The tree starting at "itemTreeRoot" should be immutable.
- (NSImage*) drawImageOfItemTree: (Item*)itemTreeRoot inRect: (NSRect)bounds;

- (void) abortDrawing;
- (void) resetAbortDrawingFlag;

@end
