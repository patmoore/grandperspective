#import "ItemPathModel.h"

#import "CompoundItem.h"
#import "DirectoryItem.h" // Imports FileItem.h
#import "TreeContext.h"


NSString  *SelectedItemChangedEvent = @"selectedItemChanged";
NSString  *VisibleTreeChangedEvent = @"visibleTreeChanged";
NSString  *VisiblePathLockingChangedEvent = @"visiblePathLockingChanged";


#define STICK_TO_ENDPOINT  0xFFFF


@interface ItemPathModel (PrivateMethods)

// Initialiser used to implement copying.
//
// Note: To properly allow subclassing, this method should maybe be moved
// to the public interface. However, this is currently not relevant, as this
// class is not subclassed.
- (id) initByCopying: (ItemPathModel *)source;

- (void) observeEvents;

- (void) treeItemReplaced: (NSNotification *)notification;

- (void) postSelectedItemChanged;
- (void) postVisibleTreeChanged;
- (void) postVisiblePathLockingChanged;

- (BOOL) buildPathToFileItem: (FileItem *)targetItem;

// "start" and "end" are both inclusive.
- (NSArray*) buildFileItemPathFromIndex:(int)start toIndex:(int)end;

- (BOOL) extendVisiblePathToFileItem: (FileItem *)target 
           similar: (BOOL) similar;
- (BOOL) extendVisiblePathToFileItem: (FileItem *)target 
           similar: (BOOL) similar fromItem: (Item *)current;

@end


@implementation ItemPathModel

// Overrides super's designated initialiser.
- (id) init {
  NSAssert(NO, @"Use -initWithTreeContext: instead.");
}

- (id) initWithTreeContext: (TreeContext *)treeContextVal {
  if (self = [super init]) {
    treeContext = [treeContextVal retain];
  
    path = [[NSMutableArray alloc] initWithCapacity: 64];
    
    [path addObject: [treeContext volumeTree]];
    lastFileItemIndex = 0;
    visibleTreeRootIndex = 0;
    selectedFileItemIndex = 0;
    
    preferredSelectionDepth = STICK_TO_ENDPOINT;
    selectionDepth = 0;

    BOOL  ok = [self buildPathToFileItem: [treeContext scanTree]];
    NSAssert(ok, @"Failed to extend path to scan tree.");
    scanTreeIndex = lastFileItemIndex;
    visibleTreeRootIndex = lastFileItemIndex;
      
    visiblePathLocked = NO;
    lastNotifiedSelectedFileItemIndex = -1;
    
    [self observeEvents];
  }

  return self;
}

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  
  [treeContext release];
  [path release];
  
  [super dealloc];
}

- (id) copyWithZone:(NSZone*) zone {
  return [[[self class] allocWithZone: zone] initByCopying: self];
}


- (NSArray*) fileItemPath {
  return [self buildFileItemPathFromIndex: 0 toIndex: lastFileItemIndex];
}

- (NSArray*) itemPath {
  // Note: For efficiency returning path directly, instead of an (immutable)
  // copy. This is done so that there is not too much overhead associated
  // with invoking ItemPathDrawer -drawVisiblePath:...: many times in short
  // successsion.
  return path;
}

- (NSArray*) itemPathToSelectedFileItem {
   return [path subarrayWithRange: NSMakeRange(0, selectedFileItemIndex + 1)];
}


- (TreeContext *) treeContext {
  return treeContext;
}

- (DirectoryItem*) volumeTree {
  return [path objectAtIndex: 0];
}

- (DirectoryItem*) scanTree {
  return [path objectAtIndex: scanTreeIndex];
}

- (FileItem*) visibleTree {
  return [path objectAtIndex: visibleTreeRootIndex];
}

- (FileItem*) selectedFileItem {
  return [path objectAtIndex: selectedFileItemIndex];
}


- (BOOL) selectionSticksToEndPoint {
  return (preferredSelectionDepth == STICK_TO_ENDPOINT);
}

- (void) setSelectionSticksToEndPoint: (BOOL)value {  
  if (value) {
    preferredSelectionDepth = STICK_TO_ENDPOINT;
    
    // Move selection to the path's endpoint
    while ([self canMoveSelectionDown]) {
      [self moveSelectionDown];
    }
  }
  else {
    // Preferred depth is the current one. The selection does not change.
    preferredSelectionDepth = selectionDepth;
  }
}


- (BOOL) isVisiblePathLocked {
  return visiblePathLocked;
}

- (void) setVisiblePathLocking:(BOOL)value {
  if (value == visiblePathLocked) {
    return; // No change: Ignore.
  }
  
  visiblePathLocked = value;
  [self postVisiblePathLockingChanged];
}


- (void) suppressSelectedItemChangedNotifications:(BOOL)option {
  if (option) {
    if (lastNotifiedSelectedFileItemIndex != -1) {
      return; // Already suppressing notifications.
    }
    lastNotifiedSelectedFileItemIndex = selectedFileItemIndex;
  }
  else {
    if (lastNotifiedSelectedFileItemIndex == -1) {
      return; // Already instantaneously generating notifications.
    }
    
    if (lastNotifiedSelectedFileItemIndex != selectedFileItemIndex) {
      [self postSelectedItemChanged];
    }
    lastNotifiedSelectedFileItemIndex = -1;
  }
}


- (BOOL) clearVisiblePath {
  NSAssert(!visiblePathLocked, @"Cannot clear path when locked.");

  int  num = [path count] - visibleTreeRootIndex - 1;

  if (num > 0) {
    [path removeObjectsInRange: NSMakeRange(visibleTreeRootIndex + 1, num)];
    
    lastFileItemIndex = visibleTreeRootIndex;

    selectedFileItemIndex = visibleTreeRootIndex;
    selectionDepth = 0;
    [self postSelectedItemChanged];
    
    return YES;
  }

  return NO;
}

- (void) extendVisiblePath: (Item *)nextItem {
  NSAssert(!visiblePathLocked, @"Cannot extend path when locked.");
   
  [path addObject: nextItem];  

  if (! [nextItem isVirtual]) {
    NSAssert( [((FileItem *)nextItem) parentDirectory] == 
                [path objectAtIndex: lastFileItemIndex], 
              @"Path parent inconsistency.");
  
    lastFileItemIndex = [path count] - 1;
    
    if (selectionDepth < preferredSelectionDepth) {
      // Automatically move selection down
      [self moveSelectionDown];
    }
  }
}


- (BOOL) clearPathBeyondSelection {
  int  num = [path count] - selectedFileItemIndex - 1;

  if (num > 0) {
    [path removeObjectsInRange: NSMakeRange(selectedFileItemIndex + 1, num)];
    
    lastFileItemIndex = selectedFileItemIndex;

    return YES;
  }

  return NO;
}


- (BOOL) extendVisiblePathToFileItem: (FileItem *)item {
  return [self extendVisiblePathToFileItem: item similar: NO];
}

- (BOOL) extendVisiblePathToSimilarFileItem: (FileItem *)item {
  return [self extendVisiblePathToFileItem: item similar: YES];
}


- (BOOL) canMoveVisibleTreeUp {
  return (visibleTreeRootIndex > scanTreeIndex);
}

- (BOOL) canMoveVisibleTreeDown {
  return (visibleTreeRootIndex < selectedFileItemIndex);
}

- (void) moveVisibleTreeUp {
  NSAssert([self canMoveVisibleTreeUp], @"Cannot move up.");

  do {
    visibleTreeRootIndex--;
  } while ([[path objectAtIndex:visibleTreeRootIndex] isVirtual]);

  // Selection has moved one level deeper as a result.
  selectionDepth++;
  
  [self postVisibleTreeChanged];
}

- (void) moveVisibleTreeDown {
  NSAssert([self canMoveVisibleTreeDown], @"Cannot move down.");

  do {
    visibleTreeRootIndex++;
  } while ([[path objectAtIndex:visibleTreeRootIndex] isVirtual]);
  
  if (selectionDepth==0) {
    // Ensure that the selected file item is always in the visible path
    selectedFileItemIndex = visibleTreeRootIndex;
    [self postSelectedItemChanged];
  }
  else {
    // Selection has moved one level higher as a result.
    selectionDepth--;
  }
  NSAssert(selectedFileItemIndex >= visibleTreeRootIndex, 
             @"Inconsistent selection state.");

  [self postVisibleTreeChanged];
}


- (BOOL) canMoveSelectionUp {
  return (selectedFileItemIndex > visibleTreeRootIndex);
}

- (BOOL) canMoveSelectionDown {
  return (selectedFileItemIndex < lastFileItemIndex);
}

- (void) moveSelectionUp {
  NSAssert([self canMoveSelectionUp], @"Cannot move up");
  NSAssert(selectionDepth > 0, @"Invalid selection depth");
  
  do {
    selectedFileItemIndex--;
  } while ([[path objectAtIndex: selectedFileItemIndex] isVirtual]);
  selectionDepth--;
  preferredSelectionDepth = selectionDepth;
    // Note: If preferred selection depth was sticky, it is not anymore.
  
  [self postSelectedItemChanged];
}

- (void) moveSelectionDown {
  NSAssert([self canMoveSelectionDown], @"Cannot move down");
  
  do {
    selectedFileItemIndex++;
  } while ([[path objectAtIndex: selectedFileItemIndex] isVirtual]);
  selectionDepth++;
  if (preferredSelectionDepth < selectionDepth) {
    preferredSelectionDepth = selectionDepth;
  }
  
  [self postSelectedItemChanged];
}

@end


@implementation ItemPathModel (PrivateMethods)

// Note: this initialisation method does not invoke the designated initialiser
// of its own class (that does not make much sense for copy-initialisation).
// So subclasses that have their own member fields will have to extend this 
// method.
- (id) initByCopying: (ItemPathModel *)source {
  if (self = [super init]) {
    treeContext = [source->treeContext retain];
    path = [[NSMutableArray alloc] initWithArray: source->path];

    visibleTreeRootIndex = source->visibleTreeRootIndex;
    scanTreeIndex = source->scanTreeIndex;
    selectedFileItemIndex = source->selectedFileItemIndex;
    lastFileItemIndex = source->lastFileItemIndex;
    
    visiblePathLocked = source->visiblePathLocked;
    lastNotifiedSelectedFileItemIndex = -1;
    
    selectionDepth = source->selectionDepth;
    preferredSelectionDepth = source->preferredSelectionDepth;
    
    [self observeEvents];
  }

  return self;  
}

- (void) observeEvents {
 [[NSNotificationCenter defaultCenter] 
      addObserver: self selector: @selector(treeItemReplaced:)
      name: TreeItemReplacedEvent object: treeContext];
}

- (void) treeItemReplaced: (NSNotification *)notification {
  FileItem  *replacedItem = [treeContext replacedFileItem];
  FileItem  *replacingItem = [treeContext replacingFileItem];

  // Check if all items in the path are still valid
  unsigned  i = [path count] - 1;
  do {
    Item  *item = [path objectAtIndex: i];
    if (item == replacedItem) {
      if (i != [path count] - 1) {
        // The replaced item was not the last in the path, so clear the rest
        // This needs to be done carefully, as the visible tree and selection
        // may actually be inside the bit that is to be removed.

        while (visibleTreeRootIndex > i) {
          [self moveVisibleTreeUp];
        }
        
        unsigned  oldValue = preferredSelectionDepth;
        while (selectedFileItemIndex > i) {
          [self moveSelectionUp];
        }
        // Do not let a forced move affect the preferred selection depth.
        preferredSelectionDepth = oldValue;

        [path removeObjectsInRange: NSMakeRange(i + 1, [path count] - i - 1)];
        
        if (lastFileItemIndex > i) {
          lastFileItemIndex = i;
        }
      }

      [path replaceObjectAtIndex: i withObject: replacingItem];
      if (i == selectedFileItemIndex) {
        [self postSelectedItemChanged];
      }
      
      // Replaced item found, so iteration can be aborted.
      break;
    } 
  } while (i-- > 0); // Condition handles fact that "i" is unsigned. 

  // Check if the replaced item was part of the visible tree.
  FileItem  *visibleTree = [self visibleTree];
  FileItem  *item = replacingItem;
  do {
    if (item == visibleTree) {
      // The item was (part of) the visible tree, so signal that it changed.
      [self postVisibleTreeChanged];
      break;
    }
    
    item = [item parentDirectory];
  } while (item != nil);
}


- (void) postSelectedItemChanged {
  if (lastNotifiedSelectedFileItemIndex == -1) {
    // Currently surpressing notifications
  }

  [[NSNotificationCenter defaultCenter]
      postNotificationName: SelectedItemChangedEvent object: self];
}

- (void) postVisibleTreeChanged {
  [[NSNotificationCenter defaultCenter]
      postNotificationName: VisibleTreeChangedEvent object: self];
}

- (void) postVisiblePathLockingChanged {
  [[NSNotificationCenter defaultCenter]
      postNotificationName: VisiblePathLockingChangedEvent object: self];
}


- (BOOL) buildPathToFileItem: (FileItem *)targetItem {
  Item  *lastItem = [path lastObject];
  
  if ([lastItem isVirtual]) {
    // Can only extend from a file item.
    return NO;
  }
  
  
  NSMutableArray  *items = [NSMutableArray arrayWithCapacity: 16];

  // Collect all file items on the path (by ascending the file hierarchy)
  FileItem  *item = targetItem;
  while (item != lastItem) {
    [items addObject: item];

    item = [item parentDirectory];
    NSAssert(item != nil, @"Did not find path end-point in ancestors.");
  }
  
  // Extend the path, starting from the top-level items.
  while ([items count] > 0) {
    if (! [self extendVisiblePathToFileItem: [items lastObject]]) {
      break;
    }

    [items removeLastObject];
  }
  
  return [items count] == 0;
}


- (NSArray*) buildFileItemPathFromIndex: (int)start toIndex: (int)end {
  NSMutableArray  *fileItemPath = [NSMutableArray arrayWithCapacity:8];

  unsigned  i = start;
  while (i <= end) {
    if (![[path objectAtIndex:i] isVirtual]) {
      [fileItemPath addObject: [path objectAtIndex:i]];
    }
    i++;
  }
  
  return fileItemPath;
}


- (BOOL) extendVisiblePathToFileItem: (FileItem *)target 
           similar: (BOOL) similar {
  NSAssert(!visiblePathLocked, @"Cannot extend path when locked.");
  
  Item  *pathEndPoint = [path lastObject];
  
  if ([pathEndPoint isVirtual] || 
      [((FileItem *)pathEndPoint) isPlainFile]) {
    // Can only extend from a DirectoryItem
    return NO;
  }
  
  if (! [self extendVisiblePathToFileItem: target similar: similar
                fromItem: [((DirectoryItem *)pathEndPoint) getContents]] ) {
    // Failed to find a similar file item
    return NO;
  }
  
  NSAssert(! [[path lastObject] isVirtual], @"Unexpected virtual endpoint.");
  lastFileItemIndex = [path count] - 1;


  if (selectionDepth < preferredSelectionDepth) {
    // Automatically move the selection down.
    [self moveSelectionDown];
  }
  
  return YES;
}

- (BOOL) extendVisiblePathToFileItem: (FileItem *)target 
           similar: (BOOL) similar fromItem: (Item *)current {
  [path addObject: current];
  
  if ([current isVirtual]) {
    CompoundItem  *compoundItem = (CompoundItem*)current;
    
    if ([self extendVisiblePathToFileItem: target similar: similar
                fromItem: [compoundItem getFirst]]) {
      return YES;  
    }
    if ([self extendVisiblePathToFileItem: target similar: similar
                fromItem: [compoundItem getSecond]]) {
      return YES;
    }
  }
  else {
    FileItem  *fileItem = (FileItem*)current;

    if (target == fileItem ||
          (similar &&
             ([[fileItem name] isEqualToString: [target name]] &&
              [fileItem isPlainFile] == [target isPlainFile] &&
              [fileItem isSpecial] == [target isSpecial]))) {
      return YES;
    }
  }
  
  // Item not found in this part of the tree, so back-track.
  [path removeLastObject];
  
  return NO;
}

@end