#import <Cocoa/Cocoa.h>

#import "TreeLayoutTraverser.h"

@class Item;
@class TreeLayoutBuilder;
@class FileItemHashing;
@class ColorPalette;
@class FileItemPathStringCache;
@protocol FileItemTest;

@interface ItemTreeDrawer : NSObject <TreeLayoutTraverser> {

  FileItemHashing  *colorMapping;
  NSObject<FileItemTest>  *fileItemMask;
  
  FileItemPathStringCache  *fileItemPathStringCache;
  
  TreeLayoutBuilder  *layoutBuilder;

  NSColorList  *colorPalette;
  BOOL  initGradientColors;
  UInt32  *gradientColors;
  int  numGradientColors;

  NSBitmapImageRep  *drawBitmap;
  BOOL  abort;
}

- (id) initWithLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder;

- (id) initWithLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder
         colorMapping: (FileItemHashing *)colorMapping
         colorPalette: (NSColorList *)colorPalette;


- (TreeLayoutBuilder *) treeLayoutBuilder;

- (void) setFileItemMask: (NSObject <FileItemTest> *)fileItemMask;
- (NSObject <FileItemTest> *) fileItemMask;

- (void) setColorMapping: (FileItemHashing *)colorMapping;
- (FileItemHashing *) colorMapping;

- (void) setColorPalette: (NSColorList *)colorPalette;
- (NSColorList *) colorPalette;

// The tree starting at "itemTree" should be immutable.
- (NSImage *) drawImageOfItemTree: (Item *)itemTree inRect: (NSRect) bounds;

- (void) abortDrawing;

@end
