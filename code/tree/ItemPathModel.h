#import <Cocoa/Cocoa.h>

@class Item;
@class FileItem;
@class DirectoryItem;

@interface ItemPathModel : NSObject<NSCopying> {
  // Contains the FileItems from the root until the end of the path.
  NSMutableArray  *path;

  // The index in the path array where the subtree starts (always a FileItem)
  unsigned  visibleTreeRootIndex;
  
  // The root of the scan tree. The visible tree should always be inside the
  // scan tree.
  unsigned  scanTreeIndex;

  // The index in the path array where the selected file item is.
  //
  // Note: It is always part of the visible item path)
  unsigned  selectedFileItemIndex;
  
  // The index in the path array where the visible file path ends (always a 
  // FileItem).
  //
  // Note: It is not necessarily always the last item in the array, as one
  // or more virtual items may still follow (in particular when the path is 
  // being extended).
  unsigned  lastFileItemIndex;
  
  // Controls if "selectedItemChanged" notifications are being (temporarily)
  // supressed. If it is set to -1, they are posted as they occur. Otherwise
  // it will suppress notifications, but remember the current selection state. 
  // As soon as notifications are enabled again, it will check if a 
  // notification needs to be fired. 
  int  lastNotifiedSelectedFileItemIndex;
  
  // Relative to the visible tree root.
  unsigned  selectionDepth;
  unsigned  preferredSelectionDepth;
  
  // If it is set to "NO", the visible item path cannot be changed.
  // (Note: the invisible part can never be changed directly. Only by first
  // making it visible can it be changed). 
  BOOL  visiblePathLocked;
}

- (id) initWithVolumeTree: (DirectoryItem *)volumeTree;


// Returns the file items in the path
- (NSArray*) fileItemPath;

// Returns all items in the path.
- (NSArray*) itemPath;

// Returns all items in the path up until (inclusive) the selected file item.
- (NSArray*) itemPathToSelectedFileItem;


// Returns the volume tree.
- (DirectoryItem*) volumeTree;

// Returns the root of the scanned tree.
- (DirectoryItem*) scanTree;

// Returns the root of the visible tree. The visible tree is the part of the
// volume tree whose treemap is drawn.
- (FileItem*) visibleTree;


// Returns the selected file item (which is always part of the visible path).
- (FileItem*) selectedFileItem;

- (BOOL) selectionSticksToEndPoint;
- (void) setSelectionSticksToEndPoint: (BOOL)value;

- (BOOL) isVisiblePathLocked;
- (void) setVisiblePathLocking:(BOOL)value;

- (void) suppressSelectedItemChangedNotifications:(BOOL)option;

- (BOOL) clearVisiblePath;
- (void) extendVisiblePath: (Item *)nextItem;

// Attemps to extend the path with a file item equal to the specified one.
//
// Note: The path is extended with at most one file item. I.e. it does not
// recurse into subdirectories.
- (BOOL) extendVisiblePathToFileItem: (FileItem *)item;

// Attemps to extend the path with a file item similar to the specified one.
// A file item is similar if it has the same name, and the "isSpecial" 
// attribute matches.
//
// Note: The path is extended with at most one file item. I.e. it does not
// recurse into subdirectories.
- (BOOL) extendVisiblePathToSimilarFileItem: (FileItem *)item;

- (BOOL) canMoveVisibleTreeUp;
- (BOOL) canMoveVisibleTreeDown;
- (void) moveVisibleTreeUp;
- (void) moveVisibleTreeDown;

- (BOOL) canMoveSelectionUp;
- (BOOL) canMoveSelectionDown;
- (void) moveSelectionUp;
- (void) moveSelectionDown;

@end
