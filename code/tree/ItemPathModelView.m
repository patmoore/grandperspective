#import "ItemPathModelView.h"


#import "DirectoryItem.h" // Imports FileItem.h
#import "ItemPathModel.h"
#import "ItemPathBuilder.h"


#define STICK_TO_ENDPOINT  0xFFFF

@interface ItemPathModelView (PrivateMethods)

/* Updates its own state, based on the underlying model and its own settings.
 */
- (void) updatePath;

/* Updates the selected item in the underlying model, given the settings of
 * the view.
 */
- (void) updateSelectedItemInModel;

/* Returns the index in the fileItemPath corresponding to the given file item.
 * When package contents are hidden and the given item resides insides a 
 * package, then the index will end up pointing to the package containing the
 * item, as opposed to the item directly.
 */
- (int) indexCorrespondingToItem: (FileItem *)targetItem 
          startingAt: (int) index;

/* Sends selection-changed events, which comprise selection-changes inside
 * the path, as well as selection of "invisible" items outside the path.
 */
- (void) postSelectedItemChanged;

- (void) postVisibleTreeChanged;

- (void) selectedItemChanged: (NSNotification *)notification;
- (void) visibleTreeChanged: (NSNotification *)notification;

@end


@implementation ItemPathModelView

- (id) initWithPathModel: (ItemPathModel *)pathModelVal {
  if (self = [super init]) {
    pathModel = [pathModelVal retain];
    pathBuilder = [[ItemPathBuilder alloc] init];
    fileItemPath = (NSMutableArray *)
      [pathModel fileItemPath: [[NSMutableArray alloc] initWithCapacity: 16]];
    scanTreeIndex = [self indexCorrespondingToItem: [pathModel scanTree] 
                            startingAt: 0];
    
    invisibleSelectedItem = nil;
    showPackageContents = YES;
    
    [self updatePath];
    
    automaticallyStickToEndPoint = YES;
    if (automaticallyStickToEndPoint && ![self canMoveSelectionDown]) {
      // We're at the end-point. Make depth stick to end-point. 
      preferredSelectionDepth = STICK_TO_ENDPOINT;
    }
    else {
      preferredSelectionDepth = selectedItemIndex - visibleTreeIndex; 
    }
    
    NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver: self selector: @selector(selectedItemChanged:)
          name: SelectedItemChangedEvent object: pathModel];
    [nc addObserver: self selector: @selector(visibleTreeChanged:)
          name: VisibleTreeChangedEvent object: pathModel];
  }
  
  return self;
}

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  
  [pathBuilder release];
  [pathModel release];
  [fileItemPath release];
  [invisibleSelectedItem release];
  
  [super dealloc];
}

/* Returns the path model that is wrapped by this view.
 */
- (ItemPathModel *) pathModel {
  return pathModel;
}


- (void) setShowPackageContents: (BOOL) showPackageContentsVal {
  if (showPackageContents != showPackageContentsVal) {
    showPackageContents = showPackageContentsVal;
    
    [self updatePath];
  }
}

- (BOOL) showPackageContents {
  return showPackageContents;
}


- (void) selectItemAtPoint: (NSPoint) point 
           startingAtTree: (FileItem *)treeRoot
           usingLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder 
           bounds: (NSRect) bounds {
  
  FileItem  *oldInvisibleSelectedItem = invisibleSelectedItem;
  
  // Don't generate notifications while the path is being built.
  [pathModel suppressSelectedItemChangedNotifications: YES];
  
  // Get the item at the given point (updating the path as far as possible)
  FileItem  *itemAtPoint =
    [pathBuilder itemAtPoint: point 
                   startingAtTree: treeRoot
                   usingLayoutBuilder: layoutBuilder 
                   bounds: bounds
                   updatePath: pathModel];
  
  [self updateSelectedItemInModel];
  
  [pathModel suppressSelectedItemChangedNotifications: NO]; 

  if ([[self visibleTree] isAncestorOfFileItem: itemAtPoint]) {
    // The item is inside the visible tree. The selection can therefore be
    // managed using the fileItemPath array.
    [invisibleSelectedItem release]; 
    invisibleSelectedItem = nil;
  }
  else {
    // The item is outside the visible tree. The fileItemPath array can 
    // therefore not be used to manage its selection, so this needs to be
    // done explicitly.
    
    NSAssert([pathModel selectedFileItem] == [pathModel visibleTree], 
               @"Unexpected pathModel state.");
    
    [invisibleSelectedItem release];
    invisibleSelectedItem = [itemAtPoint retain];
  }
  
  if (oldInvisibleSelectedItem != invisibleSelectedItem) {
    // Only post changes here to the invisible item. When the selected item
    // in the path changed, -selectedItemChanged will be notified and post the 
    // event in response. 
    [self postSelectedItemChanged];
  }
}


- (DirectoryItem *) volumeTree {
  return [pathModel volumeTree];
}

- (DirectoryItem *) scanTree {
  return [pathModel scanTree];
}

- (FileItem *) visibleTree {
  return [fileItemPath objectAtIndex: visibleTreeIndex];
}


- (FileItem *) selectedFileItem {
  FileItem  *selectedItem = [self selectedFileItemInTree];
  
  return ( (!showPackageContents && [selectedItem isDirectory]) 
           ? [((DirectoryItem *)selectedItem) itemWhenHidingPackageContents]
           : selectedItem ); 
}

- (FileItem *) selectedFileItemInTree {
  return (invisibleSelectedItem != nil
          ? invisibleSelectedItem
          : [fileItemPath objectAtIndex: selectedItemIndex]);
}


- (BOOL) isSelectedFileItemVisible {
  return (invisibleSelectedItem == nil);
}


- (BOOL) canMoveVisibleTreeUp {
  return (visibleTreeIndex > scanTreeIndex);
}

- (BOOL) canMoveVisibleTreeDown {
  return (visibleTreeIndex < selectedItemIndex);
}

- (void) moveVisibleTreeUp {
  NSAssert([self canMoveVisibleTreeUp], @"Cannot move visible tree up.");

  // May require multiple moves in the wrapped model, as the visible tree there
  // could be inside a package.
  FileItem  *newVisibleTree = 
    [fileItemPath objectAtIndex: visibleTreeIndex - 1];

  [pathModel suppressVisibleTreeChangedNotifications: YES];
  do {
    [pathModel moveVisibleTreeUp];
  } while ([pathModel visibleTree] != newVisibleTree);
  [pathModel suppressVisibleTreeChangedNotifications: NO];
}

- (void) moveVisibleTreeDown {
  NSAssert([self canMoveVisibleTreeDown], @"Cannot move visible tree down.");
  
  [pathModel moveVisibleTreeDown];
}



- (BOOL) selectionSticksToEndPoint {
  return (preferredSelectionDepth == STICK_TO_ENDPOINT);
}

- (void) setSelectionSticksToEndPoint: (BOOL)value { 
  if (value) {
    preferredSelectionDepth = STICK_TO_ENDPOINT;
    
    [pathModel selectFileItem: 
      [fileItemPath objectAtIndex: lastSelectableItemIndex]];
  }
  else {
    // Preferred depth is the current one. The selection does not change.
    preferredSelectionDepth = selectedItemIndex - visibleTreeIndex;
  }
}


- (BOOL) selectionSticksAutomaticallyToEndPoint {
  return automaticallyStickToEndPoint;
}

- (void) setSelectionSticksAutomaticallyToEndPoint: (BOOL)flag {
  automaticallyStickToEndPoint = flag;
}


- (BOOL) canMoveSelectionUp {
  return (selectedItemIndex > visibleTreeIndex);
}

- (BOOL) canMoveSelectionDown {
  return (selectedItemIndex < lastSelectableItemIndex);
}

- (void) moveSelectionUp {
  NSAssert([self canMoveSelectionUp], @"Cannot move selection up");
  
  // If preferred depth was sticky, it is not anymore.
  preferredSelectionDepth = selectedItemIndex - 1 - visibleTreeIndex;
  
  [pathModel selectFileItem: 
    [fileItemPath objectAtIndex: selectedItemIndex - 1]];
}

- (void) moveSelectionDown {
  NSAssert([self canMoveSelectionDown], @"Cannot move selection down.");
  
  [pathModel selectFileItem: 
    [fileItemPath objectAtIndex: selectedItemIndex + 1]];
    
  if (automaticallyStickToEndPoint && ![self canMoveSelectionDown]) {
    // End-point reached. Make depth stick to end-point automatically 
    preferredSelectionDepth = STICK_TO_ENDPOINT;
  }
  else {
    preferredSelectionDepth = selectedItemIndex + 1 - visibleTreeIndex; 
  }
}

@end



@implementation ItemPathModelView (PrivateMethods)

- (void) updatePath {
  NSArray  *updatedPath = [pathModel fileItemPath: fileItemPath];
  NSAssert(updatedPath == fileItemPath, @"Arrays differ unexpectedly.");
    
  // Set the visible item
  visibleTreeIndex = 
    [self indexCorrespondingToItem: [pathModel visibleTree] 
            startingAt: scanTreeIndex];
  
  // Set the selected item
  selectedItemIndex = 
    [self indexCorrespondingToItem: [pathModel selectedFileItem] 
            startingAt: visibleTreeIndex];

  // Find the last item that can be selected
  lastSelectableItemIndex = 
    [self indexCorrespondingToItem: nil 
            startingAt: selectedItemIndex];

}


- (void) updateSelectedItemInModel {
  NSArray  *updatedPath = [pathModel fileItemPath: fileItemPath];
  NSAssert(updatedPath == fileItemPath, @"Arrays differ unexpectedly.");
  
  // Set the visible item
  visibleTreeIndex = 
    [self indexCorrespondingToItem: [pathModel visibleTree] 
            startingAt: scanTreeIndex];
            
  // Find the last item that can be selected
  lastSelectableItemIndex = 
    [self indexCorrespondingToItem: nil 
            startingAt: visibleTreeIndex];
    
  int  indexToSelect;
  if (preferredSelectionDepth == STICK_TO_ENDPOINT) {
    indexToSelect = lastSelectableItemIndex;
  }
  else {
    indexToSelect = MIN(visibleTreeIndex + preferredSelectionDepth, 
                        lastSelectableItemIndex);
  }
  [pathModel selectFileItem: [fileItemPath objectAtIndex: indexToSelect]];
}


- (int) indexCorrespondingToItem: (FileItem *)targetItem 
          startingAt: (int) index {
  int  maxIndex = [fileItemPath count] - 1;
  
  while (YES) {
    FileItem  *fileItem = [fileItemPath objectAtIndex: index];
    
    if (fileItem == targetItem) {
      // Got to the visible tree
      break;
    }

    if ( !showPackageContents &&
         [fileItem isDirectory] &&
         [((DirectoryItem *)fileItem) isPackage] ) {
      // Got to a package whose contents should remain hidden
      break;
    }
    
    if (index == maxIndex) {
      // Reached the end of the array
      break;
    }
    
    index++;
  }
  
  return index;
}

- (void) postSelectedItemChanged {
  [[NSNotificationCenter defaultCenter]
      postNotificationName: SelectedItemChangedEvent object: self];
}

- (void) postVisibleTreeChanged {
  [[NSNotificationCenter defaultCenter]
      postNotificationName: VisibleTreeChangedEvent object: self];
}


// Called when selection changes in path
- (void) selectedItemChanged: (NSNotification *)notification {
  if (invisibleSelectedItem != nil) {
    // Set the view's selected item to that of the path.
    [invisibleSelectedItem release]; 
    invisibleSelectedItem = nil;
  }
  
  [self updatePath];
  
  // Propagate event to my listeners.
  [self postSelectedItemChanged];
}

- (void) visibleTreeChanged: (NSNotification *)notification {
  [self updatePath];
   
  // Propagate event to my listeners.
  [self postVisibleTreeChanged];
}

@end // ItemPathModelView (PrivateMethods)
