#import <Cocoa/Cocoa.h>

#import "TreeLayoutTraverser.h"
#import "GradientRectangleDrawer.h"

@class FileItem;
@class DirectoryItem;
@class TreeLayoutBuilder;
@class TreeDrawerSettings;
@class FilteredTreeGuide;
@protocol FileItemMapping;
@protocol FileItemTest;

@interface TreeDrawer : GradientRectangleDrawer <TreeLayoutTraverser> {
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
         treeDrawerSettings: (TreeDrawerSettings *)settings;

- (void) setFileItemMask: (NSObject <FileItemTest> *)fileItemMask;
- (NSObject <FileItemTest> *) fileItemMask;

- (void) setColorMapper: (NSObject <FileItemMapping> *)colorMapper;
- (NSObject <FileItemMapping> *) colorMapper;

- (void) setShowPackageContents: (BOOL) showPackageContents;
- (BOOL) showPackageContents;

// Updates the drawer according to the given settings.
- (void) updateSettings: (TreeDrawerSettings *)settings;

// Note: The tree starting at "treeRoot" should be immutable.
- (NSImage *) drawImageOfVisibleTree: (FileItem *)visibleTree
                startingAtTree: (FileItem *)treeRoot
                usingLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder
                inRect: (NSRect) bounds;

/* Any outstanding request to abort Drawing is cancelled.
 */
- (void) clearAbortFlag;

/* Cancels any ongoing drawing task. Note: It is possible that the ongoing
 * task is just finishing, in which case it may still finish normally. 
 * Therefore, -clearAbortFlag should be invoked before initiating a new 
 * drawing task, otherwise the next drawing task will be aborted immediately.
 */
- (void) abortDrawing;

@end
