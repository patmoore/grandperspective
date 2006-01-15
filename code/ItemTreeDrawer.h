#import <Cocoa/Cocoa.h>

//#import "TreeLayoutTraverser.h"

@class Item;
@class TreeLayoutBuilder;
@class FileItemHashing;
@class ColorPalette;

@interface ItemTreeDrawer : NSObject {

  FileItemHashing  *fileItemHashing;

  // Only set when it has not yet been loaded into the gradient array.
  ColorPalette  *colorPalette;
  UInt32  *gradientColors;
  int  numGradientColors;

  NSBitmapImageRep  *drawBitmap;
  BOOL  abort;
}

- (id) initWithFileItemHashing:(FileItemHashing*)fileItemHashing;

- (id) initWithFileItemHashing:(FileItemHashing*)fileItemHashing
                  colorPalette:(ColorPalette*)colorPalette;

- (void) setFileItemHashing:(FileItemHashing*)fileItemHashing;
- (FileItemHashing*) fileItemHashing;

- (void) setColorPalette:(ColorPalette*)colorPalette;

// Both "itemTreeRoot" and "layoutBuilder" should be immutable.
- (NSImage*) drawImageOfItemTree:(Item*)itemTreeRoot 
           usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder
           inRect:(NSRect)bounds;

- (void) abortDrawing;

@end
