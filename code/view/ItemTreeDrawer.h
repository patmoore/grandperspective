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
  DirectoryItem  *volumeTree;

  FileItemHashing  *colorMapping;
  NSObject<FileItemTest>  *fileItemMask;
  BOOL  showEntireVolume;
  
  FileItemPathStringCache  *fileItemPathStringCache;
  
  NSColorList  *colorPalette;
  BOOL  initGradientColors;
  UInt32  *gradientColors;
  int  numGradientColors;
  UInt32  freeSpaceColor;
  UInt32  usedSpaceColor;

  FileItem  *visibleTree;
  BOOL  insideVisibleTree;

  NSBitmapImageRep  *drawBitmap;
  BOOL  abort;
}

// The tree starting at "volumeTree" should be immutable.
- (id) initWithVolumeTree: (DirectoryItem *)volumeTree;
- (id) initWithVolumeTree: (DirectoryItem *)volumeTree
         treeDrawerSettings: (ItemTreeDrawerSettings *)settings;

- (void) setFileItemMask: (NSObject <FileItemTest> *)fileItemMask;
- (NSObject <FileItemTest> *) fileItemMask;

- (void) setColorMapping: (FileItemHashing *)colorMapping;
- (FileItemHashing *) colorMapping;

- (void) setColorPalette: (NSColorList *)colorPalette;
- (NSColorList *) colorPalette;

- (void) setShowEntireVolume: (BOOL) flag;
- (BOOL) showEntireVolume;

// Updates the drawer according to the given settings.
- (void) updateSettings: (ItemTreeDrawerSettings *)settings;

- (NSImage *) drawImageOfVisibleTree: (FileItem *)visibleTree
                usingLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder
                inRect: (NSRect) bounds;

- (void) abortDrawing;

@end
