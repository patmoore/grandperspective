#import <Cocoa/Cocoa.h>

#import "TreeLayoutTraverser.h"

@class Item;
@class TreeLayoutBuilder;
@class FileItemHashing;
@class ColorPalette;
@protocol FileItemTest;

@interface ItemTreeDrawer : NSObject <TreeLayoutTraverser> {

  FileItemHashing  *colorMapping;
  NSObject<FileItemTest>  *fileItemMask;
  
  TreeLayoutBuilder  *layoutBuilder;

  NSColorList  *colorPalette;
  BOOL  initGradientColors;
  UInt32  *gradientColors;
  int  numGradientColors;

  NSBitmapImageRep  *drawBitmap;
  BOOL  abort;
}

- (id) initWithColorMapping: (FileItemHashing *)colorMapping;

- (id) initWithColorMapping: (FileItemHashing *)colorMapping
         colorPalette: (NSColorList*)colorPalette
         layoutBuilder: (TreeLayoutBuilder*)layoutBuilder;

- (void) setTreeLayoutBuilder: (TreeLayoutBuilder*)layoutBuilder;
- (TreeLayoutBuilder*) treeLayoutBuilder;

- (void) setFileItemMask:(NSObject <FileItemTest>*)fileItemMask;
- (NSObject <FileItemTest> *) fileItemMask;

- (void) setColorMapping: (FileItemHashing *)colorMapping;
- (FileItemHashing*) colorMapping;

- (void) setColorPalette: (NSColorList*)colorPalette;
- (NSColorList*) colorPalette;

// The tree starting at "itemTreeRoot" should be immutable.
- (NSImage*) drawImageOfItemTree: (Item*)itemTreeRoot inRect: (NSRect)bounds;

- (void) abortDrawing;

@end
