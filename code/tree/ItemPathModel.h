#import <Cocoa/Cocoa.h>

@class Item;
@class FileItem;
@class DirectoryItem;

@interface ItemPathModel : NSObject<NSCopying> {
  // Contains the FileItems from the root until the end of the path. It may
  // also be used to store the intermediate virtual items. This can be
  // useful, for instance, when the path needs to be drawn in the tree view.
  NSMutableArray  *path;

  // The index in the path array where the subtree starts (always a FileItem)
  unsigned  visibleTreeRootIndex;

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
  unsigned lastFileItemIndex;
  
  // Controls if "selectedItemChanged" notifications are being (temporarily)
  // supressed. If it is set to -1, they are posted as they occur. Otherwise
  // it will suppress notifications, but remember the current selection state. 
  // As soon as notifications are enabled again, it will check if a 
  // notification needs to be fired. 
  int  lastNotifiedSelectedFileItemIndex;
  
  // If it is set to "false", the visible item path cannot be changed.
  // (Note: the invisible part can never be changed directly. Only by first
  // making it visible can it be changed). 
  BOOL  visibleItemPathLocked;
}

- (id) initWithTree:(DirectoryItem*)itemTreeRoot;


// Returns the file items in the invisble part of the path until (inclusive)
// root in view.
- (NSArray*) invisibleFileItemPath;

// Returns the file items in the visible part of the path up until the 
// selected file item (excluding root in view).
- (NSArray*) visibleSelectedFileItemPath;

// Returns the file items in the visible part of the path (excluding root in 
// view).
- (NSArray*) visibleFileItemPath;


// Returns all items in the path.
- (NSArray*) itemPath;

// Returns all items in the path up until (inclusive) the selected file item.
- (NSArray*) itemPathToSelectedFileItem;


// Returns the root of the entire tree.
- (FileItem*) rootFileItem;

// Returns the root of the visible tree.
- (FileItem*) visibleRootFileItem;

// Returns the selected file item (which is always part of the visible path).
- (FileItem*) selectedFileItem;

// Returns the last file item in the path.
- (FileItem*) fileItemPathEndPoint;


- (BOOL) isVisibleItemPathLocked;
- (void) setVisibleItemPathLocking:(BOOL)value;

- (void) suppressSelectedItemChangedNotifications:(BOOL)option;

- (BOOL) clearVisibleItemPath;
- (void) extendVisibleItemPath:(Item*)nextItem;
- (BOOL) extendVisibleItemPathToFileItemWithName:(NSString*)name;

- (DirectoryItem*) itemTree;
- (FileItem*) visibleItemTree;

- (BOOL) canMoveTreeViewUp;
- (BOOL) canMoveTreeViewDown;
- (void) moveTreeViewUp;
- (void) moveTreeViewDown;

- (BOOL) canMoveSelectionUp;
- (BOOL) canMoveSelectionDown;
- (void) moveSelectionUp;
- (void) moveSelectionDown;

@end
