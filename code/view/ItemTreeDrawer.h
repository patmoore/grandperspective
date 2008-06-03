#import <Cocoa/Cocoa.h>

#import "TreeLayoutTraverser.h"
#import "GradientRectangleDrawer.h"

@class FileItem;
@class DirectoryItem;
@class TreeLayoutBuilder;
@class ItemTreeDrawerSettings;
@class FilteredTreeGuide;
@protocol FileItemMapping;
@protocol FileItemTest;

@interface ItemTreeDrawer : GradientRectangleDrawer <TreeLayoutTraverser> {
  NSObject <FileItemMapping>  *colorMapper;
  FilteredTreeGuide  *treeGuide;
  
  UInt32  freeSpaceColor;
  UInt32  usedSpaceColor;
  UInt32  visibleTreeBackgroundColor;

  DirectoryItem  *scanTree;
  
  FileItem  *visibleTree;
  BOOL  insideVisibleTree;

  BOOL  abort;
}

- (id) initWithScanTree: (DirectoryItem *)scanTree;
- (id) initWithScanTree: (DirectoryItem *)scanTree 
         treeDrawerSettings: (ItemTreeDrawerSettings *)settings;

- (void) setFileItemMask: (NSObject <FileItemTest> *)fileItemMask;
- (NSObject <FileItemTest> *) fileItemMask;

- (void) setColorMapper: (NSObject <FileItemMapping> *)colorMapper;
- (NSObject <FileItemMapping> *) colorMapper;

- (void) setShowPackageContents: (BOOL) showPackageContents;
- (BOOL) showPackageContents;

// Updates the drawer according to the given settings.
- (void) updateSettings: (ItemTreeDrawerSettings *)settings;

// Note: The tree starting at "treeRoot" should be immutable.
- (NSImage *) drawImageOfVisibleTree: (FileItem *)visibleTree
                startingAtTree: (FileItem *)treeRoot
                usingLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder
                inRect: (NSRect) bounds;

- (void) abortDrawing;

@end
