#import <Cocoa/Cocoa.h>

#import "TreeLayoutTraverser.h"

@class TreeLayoutBuilder;
@class FileItemHashing;
@class ColorPalette;

@interface ItemTreeDrawer : NSObject <TreeLayoutTraverser> {

  FileItemHashing  *fileItemHashing;

  // Only set when it has not yet been loaded into the gradient array.
  ColorPalette  *colorPalette;
  UInt32  *gradientColors;
  int  numGradientColors;

  NSImage  *image;
  NSBitmapImageRep  *drawBitmap;

  NSConditionLock  *workLock;
  NSLock           *settingsLock;  
  BOOL             abort;

  // Settings for next drawing task
  Item               *drawItemTree; // Assumed to be immutable
  TreeLayoutBuilder  *drawLayoutBuilder; // Assumed to be immutable
  NSRect             drawInRect;
}

- (id) initWithFileItemHashing:(FileItemHashing*)fileItemHashing;

- (id) initWithFileItemHashing:(FileItemHashing*)fileItemHashing
                  colorPalette:(ColorPalette*)colorPalette;

- (void) setFileItemHashing:(FileItemHashing*)fileItemHashing;
- (FileItemHashing*) fileItemHashing;

- (void) setColorPalette:(ColorPalette*)colorPalette;

// Both "itemTreeRoot" and "layoutBuilder" should be immutable.
- (void) drawItemTree:(Item*)itemTreeRoot 
           usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder
           inRect:(NSRect)bounds;

- (NSImage*) getImage;
- (void) resetImage;

@end
