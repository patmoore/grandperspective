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
  
  // The index in the path array where the visible file path ends (always a 
  // FileItem).
  //
  // Note: It is not necessarily always the last item in the array, as one
  // or more virtual items may still follow (in particular while the path is 
  // currently being extended).
  unsigned lastFileItemIndex;
  
  // Controls if "visibleItemPathChanged" notifications are being (temporarily)
  // supressed. If it is set to "nil", they are posted as they occur. Otherwise
  // it will suppress notifications, but remember the state of the path when
  // the last notification was posted by remembering the endpoint. As soon as
  // it is switched back to nil, it will check if the path has indeed changed,
  // and if so, fire a notification. 
  Item*  lastNotifiedPathEndPoint;
  
  // If it is set to "false", the visible item path cannot be changed.
  // (Note: the invisible part can never be changed directly. Only by first
  // making it visible can it be changed). 
  BOOL  visibleItemPathLocked;
}

- (id) initWithTree:(DirectoryItem*)itemTreeRoot;

// Returns the file items in the invisble part of the path until (inclusive)
// root in view.
- (NSArray*) invisibleFileItemPath;

// Returns the file items in the visible part of the path (excluding root in 
// view).
- (NSArray*) visibleFileItemPath;

// Returns all items in the invisble part of the path until (inclusive) root 
// in view.
- (NSArray*) invisibleItemPath;

// Returns all items in the visible part of the path (excluding root in view).
- (NSArray*) visibleItemPath;

// Returns all items in the path.
- (NSArray*) itemPath;

// Returns the last file item in the path.
- (FileItem*) fileItemPathEndPoint;

// The path name for the root of the tree. 
- (NSString*) rootFilePathName;

// The path name of the invisible part of the path until (inclusive) the root 
// in the view. The path is relative to that returned by -rootFilePathName.
- (NSString*) invisibleFilePathName;

// The path name that is visible (excluding the root in the view). So the path
// is relative to that returned by -invisibleFilePathName.
- (NSString*) visibleFilePathName;


- (BOOL) isVisibleItemPathLocked;
- (void) setVisibleItemPathLocking:(BOOL)value;

- (void) suppressItemPathChangedNotifications:(BOOL)option;

- (BOOL) clearVisibleItemPath;
- (void) extendVisibleItemPath:(Item*)nextItem;
- (BOOL) extendVisibleItemPathToFileItemWithName:(NSString*)name;

- (DirectoryItem*) itemTree;
- (FileItem*) visibleItemTree;

- (BOOL) canMoveTreeViewUp;
- (BOOL) canMoveTreeViewDown;
- (void) moveTreeViewUp;
- (void) moveTreeViewDown;

@end
