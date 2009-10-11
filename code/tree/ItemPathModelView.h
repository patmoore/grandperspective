#import <Cocoa/Cocoa.h>


@class FileItem;
@class DirectoryItem;
@class ItemPathModel;
@class ItemPathBuilder;
@class TreeLayoutBuilder;


/* Provides a view of a specific item path model. This view can be used to
 * change how a path appears in a specific DirectoryView. For example, it can
 * be used to hide package contents. Furthermore, it can maintain the selected
 * item when it is outside the visible tree (this can happen when the entire
 * volume is shown). Finally, it can manage selections of folders along the
 * path (with a view-specific and changeable preferred selection depth).
 */
@interface ItemPathModelView : NSObject {
  
  ItemPathBuilder  *pathBuilder;

  ItemPathModel  *pathModel;

  BOOL  showPackageContents;
  
  // Contains all file items in the path, as they appear in the 
  NSMutableArray  *fileItemPath;

  // The index in the path array where the scan tree starts
  unsigned  scanTreeIndex;
  
  // The index in the path array where the visible tree starts
  unsigned  visibleTreeIndex;
  
  // The index in the path array where the selected file item is.
  //
  // Note: It is always part of the visible item path)
  unsigned  selectedItemIndex;
  
  // The index in the path array of the last file item that can be selected.
  // This is not necessarily the last item in the array when package contents
  // are hidden, as some file items may be inside a package.
  unsigned  lastSelectableItemIndex;

  
  // Maintains the selected item if it is outside the visible tree (in which
  // case it is not in the path). This can happen when the entire volume is 
  // shown.
  FileItem  *invisibleSelectedItem;
  
  
  // Relative to the visible tree root.
  unsigned  preferredSelectionDepth; 

  // Controls if the selection should be made to automatically stick to the
  // end point, when the end-point is reached when explicitly moving the
  // selection down.
  BOOL  automaticallyStickToEndPoint;
}

- (id) initWithPathModel: (ItemPathModel *)pathModel;

/* Returns the path model that is wrapped by this view.
 */
- (ItemPathModel *) pathModel;


- (void) setShowPackageContents: (BOOL) showPackageContents;
- (BOOL) showPackageContents;

- (void) selectItemAtPoint: (NSPoint) point 
           startingAtTree: (FileItem *)treeRoot
           usingLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder 
           bounds: (NSRect) bounds;


/* Returns the volume tree. It is the same as that of the underlying model.
 */
- (DirectoryItem *) volumeTree;

/* Returns the root of the scanned tree. It is the same as that of the 
 * underlying model.
 */
- (DirectoryItem *) scanTree;

/* Returns the root of the visible tree. The visible tree is the part of the
 * volume tree whose treemap is drawn.
 *
 * It may differ from the visible tree of the item path model that is wrapped. 
 * The reason is that the visible tree never moves inside a package when 
 * package contents are not shown.
 */
- (FileItem *) visibleTree;

/* Returns the selected file item.
 *
 * It may differ from the selected file item of the item path model for three 
 * reasons: 
 *
 * 1) When package contents are not shown, the view will return a plain file
 * item when the selected item is a directory.
 * 2) When package contents are not shown, the view ensures that the selected 
 * item is not part of a package inside the visible tree (it may still be
 * inside a package, if the visible tree itself is inside one). If it is, the 
 * package is selected.
 * 3) When the entire volume is shown, the selected item may be outside the
 * visible tree. In this case, it will be returned by the view whereas the
 * underlying model will not have a selection (as its selected item should
 * always be part of the visible path).
 */
- (FileItem *) selectedFileItem;

/* Returns the selected file item, as it appears in the tree. It can differ
 * from the one returned by -selectedFileItem, as the latter method may
 * return a stand-in for the item in the tree (e.g. it may represent a 
 * directory that is a package as a plain file).
 */
- (FileItem *) selectedFileItemInTree;


/* Returns YES if the selected file item is inside the visible tree.
 */
- (BOOL) isSelectedFileItemVisible;


/* Returns YES iff the visible tree can be moved up a level. The constraints 
 * on up movement are the same as that of the underlying path model. 
 */
- (BOOL) canMoveVisibleTreeUp;

/* Returns YES iff the visible tree can be moved down a level. Down movement is
 * more constrained than down movement of the visible tree in the underlying
 * path model, as the visible tree cannot move inside a package when package
 * contents are hidden.
 */
- (BOOL) canMoveVisibleTreeDown;

- (void) moveVisibleTreeUp;

- (void) moveVisibleTreeDown;


- (BOOL) selectionSticksToEndPoint;
- (void) setSelectionSticksToEndPoint: (BOOL)value;

- (BOOL) selectionSticksAutomaticallyToEndPoint;
- (void) setSelectionSticksAutomaticallyToEndPoint: (BOOL)value;

- (BOOL) canMoveSelectionUp;
- (BOOL) canMoveSelectionDown;
- (void) moveSelectionUp;
- (void) moveSelectionDown;

@end
