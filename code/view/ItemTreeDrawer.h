#import <Cocoa/Cocoa.h>

#import "TreeLayoutTraverser.h"

@class FileItem;
@class DirectoryItem;
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
  UInt32  freeSpaceColor;
  UInt32  usedSpaceColor;
  UInt32  visibleTreeBackgroundColor;

  FileItem  *visibleTree;
  BOOL  insideVisibleTree;

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

// Note: The tree starting at "treeRoot" should be immutable.
- (NSImage *) drawImageOfVisibleTree: (FileItem *)visibleTree
                startingAtTree: (FileItem *)treeRoot
                usingLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder
                inRect: (NSRect) bounds;

- (void) abortDrawing;

@end
