#import <Cocoa/Cocoa.h>

#import "TreeLayoutTraverser.h"

@class Item;
@class TreeLayoutBuilder;
@class FileItemHashing;
@class ColorPalette;
@class FileItemPathStringCache;
@class ItemTreeDrawerSettings;
@protocol FileItemTest;

@interface ItemTreeDrawer : NSObject <TreeLayoutTraverser> {

  FileItemHashing  *colorMapping;
  NSObject<FileItemTest>  *fileItemMask;
  
  FileItemPathStringCache  *fileItemPathStringCache;
  
  NSColorList  *colorPalette;
  BOOL  initGradientColors;
  UInt32  *gradientColors;
  int  numGradientColors;

  NSBitmapImageRep  *drawBitmap;
  BOOL  abort;
}

- (id) init;
- (id) initWithTreeDrawerSettings: (ItemTreeDrawerSettings *)settings;


- (void) setFileItemMask: (NSObject <FileItemTest> *)fileItemMask;
- (NSObject <FileItemTest> *) fileItemMask;

- (void) setColorMapping: (FileItemHashing *)colorMapping;
- (FileItemHashing *) colorMapping;

- (void) setColorPalette: (NSColorList *)colorPalette;
- (NSColorList *) colorPalette;

// Updates the drawer according to the given settings.
- (void) updateSettings: (ItemTreeDrawerSettings *)settings;

// The tree starting at "itemTree" should be immutable.
- (NSImage *) drawImageOfItemTree: (Item *)itemTree 
                usingLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder 
                inRect: (NSRect) bounds;

- (void) abortDrawing;

@end
