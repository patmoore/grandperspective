#import "ItemPathModel.h"

#import "CompoundItem.h"
#import "DirectoryItem.h" // Imports FileItem.h
#import "TreeContext.h"


NSString  *SelectedItemChangedEvent = @"selectedItemChanged";
NSString  *VisibleTreeChangedEvent = @"visibleTreeChanged";
NSString  *VisiblePathLockingChangedEvent = @"visiblePathLockingChanged";


@interface ItemPathModel (PrivateMethods)

/* Initialiser used to implement copying.
 *
 * Note: To properly allow subclassing, this method should maybe be moved
 * to the public interface. However, this is currently not relevant, as this
 * class is not subclassed.
 */
- (id) initByCopying: (ItemPathModel *)source;

/* Registers the model for all events that it wants to be notified about.
 */
- (void) observeEvents;

- (void) fileItemDeleted: (NSNotification *)notification;

- (void) postSelectedItemChanged;
- (void) postVisibleTreeChanged;
- (void) postVisiblePathLockingChanged;

- (BOOL) buildPathToFileItem: (FileItem *)targetItem;

/* Extracts the file items from (part of) the path (which also contains 
 * virtual items).
 *
 * Note: "start" and "end" are both inclusive.
 */
- (NSArray*) buildFileItemPathFromIndex: (int) start toIndex: (int) end
               usingArray: (NSMutableArray *)array;

- (BOOL) extendVisiblePathToFileItem: (FileItem *)target 
           similar: (BOOL) similar;
- (BOOL) extendVisiblePathToFileItem: (FileItem *)target 
           similar: (BOOL) similar fromItem: (Item *)current;

@end


@implementation ItemPathModel

+ (id) pathWithTreeContext: (TreeContext *)treeContext {
  return [[[ItemPathModel alloc] initWithTreeContext: treeContext] autorelease];
}


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
    visibleTreeIndex = 0;
    selectedItemIndex = 0;
    
    BOOL  ok = [self buildPathToFileItem: [treeContext scanTree]];
    NSAssert(ok, @"Failed to extend path to scan tree.");
    scanTreeIndex = lastFileItemIndex;
    visibleTreeIndex = lastFileItemIndex;
    selectedItemIndex = lastFileItemIndex;
      
    visiblePathLocked = NO;
    lastNotifiedSelectedItem = nil;
    lastNotifiedVisibleTree = nil;
    
    [self observeEvents];
  }

  return self;
}

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  
  [treeContext release];
  [path release];
  
  [lastNotifiedSelectedItem release];
  [lastNotifiedVisibleTree release];
  
  [super dealloc];
}

- (id) copyWithZone:(NSZone*) zone {
  return [[[self class] allocWithZone: zone] initByCopying: self];
}


- (NSArray*) fileItemPath {
  return [self buildFileItemPathFromIndex: 0 toIndex: lastFileItemIndex
                 usingArray: [NSMutableArray arrayWithCapacity: 8]];
}

- (NSArray*) fileItemPath: (NSMutableArray *)array {
  return [self buildFileItemPathFromIndex: 0 toIndex: lastFileItemIndex
                 usingArray: array];
}

- (NSArray*) itemPath {
  // Note: For efficiency returning path directly, instead of an (immutable)
  // copy. This is done so that there is not too much overhead associated
  // with invoking ItemPathDrawer -drawVisiblePath:...: many times in short
  // successsion.
  return path;
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
  return [path objectAtIndex: visibleTreeIndex];
}

- (FileItem*) selectedFileItem {
  return [path objectAtIndex: selectedItemIndex];
}

- (FileItem *) lastFileItem {
  return [path objectAtIndex: lastFileItemIndex];
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


- (void) suppressSelectedItemChangedNotifications: (BOOL)option {
  if (option) {
    if (lastNotifiedSelectedItem != nil) {
      return; // Already suppressing notifications.
    }
    lastNotifiedSelectedItem = [[self selectedFileItem] retain];
  }
  else {
    if (lastNotifiedSelectedItem == nil) {
      return; // Already instantaneously generating notifications.
    }
    
    BOOL  changed = (lastNotifiedSelectedItem != [self selectedFileItem]);

    [lastNotifiedSelectedItem release];
    lastNotifiedSelectedItem = nil;

    if (changed) {
      [self postSelectedItemChanged];
    }
  }
}

- (void) suppressVisibleTreeChangedNotifications: (BOOL)option {
  if (option) {
    if (lastNotifiedVisibleTree != nil) {
      return; // Already suppressing notifications.
    }
    lastNotifiedVisibleTree = [[self visibleTree] retain];
  }
  else {
    if (lastNotifiedVisibleTree == nil) {
      return; // Already instantaneously generating notifications.
    }
    
    BOOL  changed = (lastNotifiedVisibleTree != [self visibleTree]);
    
    [lastNotifiedVisibleTree release];
    lastNotifiedVisibleTree = nil;
    
    if (changed) {
      [self postVisibleTreeChanged];
    }
  }
}



- (BOOL) clearVisiblePath {
  NSAssert(!visiblePathLocked, @"Cannot clear path when locked.");

  int  num = [path count] - visibleTreeIndex - 1;

  if (num > 0) {
    [path removeObjectsInRange: NSMakeRange(visibleTreeIndex + 1, num)];
    
    lastFileItemIndex = visibleTreeIndex;

    selectedItemIndex = visibleTreeIndex;
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
  }
}


- (BOOL) extendVisiblePathToFileItem: (FileItem *)item {
  return [self extendVisiblePathToFileItem: item similar: NO];
}

- (BOOL) extendVisiblePathToSimilarFileItem: (FileItem *)item {
  return [self extendVisiblePathToFileItem: item similar: YES];
}


- (BOOL) canMoveVisibleTreeUp {
  return (visibleTreeIndex > scanTreeIndex);
}

- (BOOL) canMoveVisibleTreeDown {
  return (visibleTreeIndex < lastFileItemIndex);
}

- (void) moveVisibleTreeUp {
  NSAssert([self canMoveVisibleTreeUp], @"Cannot move up.");

  do {
    visibleTreeIndex--;
  } while ([[path objectAtIndex:visibleTreeIndex] isVirtual]);
  
  [self postVisibleTreeChanged];
}

- (void) moveVisibleTreeDown {
  NSAssert([self canMoveVisibleTreeDown], @"Cannot move down.");

  do {
    visibleTreeIndex++;
  } while ([[path objectAtIndex:visibleTreeIndex] isVirtual]);
  
  if (selectedItemIndex < visibleTreeIndex) {
    // Ensure that the selected file item is always in the visible path
    selectedItemIndex = visibleTreeIndex;
    [self postSelectedItemChanged];
  }

  [self postVisibleTreeChanged];
}


- (void) selectFileItem: (FileItem *)fileItem {
  int  oldSelectedItemIndex = selectedItemIndex;
  selectedItemIndex = lastFileItemIndex;
  
  while ( [path objectAtIndex: selectedItemIndex] != fileItem ) {
    selectedItemIndex--;
    
    NSAssert(selectedItemIndex >= 0, @"Item not found.");
  }
  
  if (selectedItemIndex < visibleTreeIndex ) {
    // The item was not inside the visible part of the path, so also update
    // update the visible tree. 
    // 
    // This can happen when a view has a different, higher visible tree than 
    // the model (because it is not showing the contents of packages). When
    // the view then selects an item inside its own visible tree, this is
    // not necessarily inside the model's visible tree.

    visibleTreeIndex = selectedItemIndex;
    [self postVisibleTreeChanged];
  }
  
  if (selectedItemIndex != oldSelectedItemIndex) {
    [self postSelectedItemChanged];
  }
}

@end


@implementation ItemPathModel (PrivateMethods)

/* Note: this initialisation method does not invoke the designated initialiser
 * of its own class (that does not make much sense for copy-initialisation).
 * So subclasses that have their own member fields will have to extend this 
 * method.
 */
- (id) initByCopying: (ItemPathModel *)source {
  if (self = [super init]) {
    treeContext = [source->treeContext retain];
    path = [[NSMutableArray alloc] initWithArray: source->path];

    visibleTreeIndex = source->visibleTreeIndex;
    scanTreeIndex = source->scanTreeIndex;
    selectedItemIndex = source->selectedItemIndex;
    lastFileItemIndex = source->lastFileItemIndex;
    
    visiblePathLocked = source->visiblePathLocked;
    lastNotifiedSelectedItem = nil;
    lastNotifiedVisibleTree = nil;
    
    [self observeEvents];
  }

  return self; 
}

- (void) observeEvents {
  [[NSNotificationCenter defaultCenter] 
      addObserver: self selector: @selector(fileItemDeleted:)
      name: FileItemDeletedEvent object: treeContext];
}

- (void) fileItemDeleted: (NSNotification *)notification {
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

        [path removeObjectsInRange: NSMakeRange(i + 1, [path count] - i - 1)];
        
        while (visibleTreeIndex > i) {
          visibleTreeIndex = i;
          [self postVisibleTreeChanged];
        }
        
        while (selectedItemIndex > i) {
          selectedItemIndex = i;
          [self postSelectedItemChanged];
        }
        
        if (lastFileItemIndex > i) {
          lastFileItemIndex = i;
        }
      }

      [path replaceObjectAtIndex: i withObject: replacingItem];
      if (i == selectedItemIndex) {
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
  if (lastNotifiedSelectedItem != nil) {
    // Currently surpressing notifications
    return;
  }
  
  [[NSNotificationCenter defaultCenter]
      postNotificationName: SelectedItemChangedEvent object: self];
}

- (void) postVisibleTreeChanged {
  if (lastNotifiedVisibleTree != nil) {
    // Currently surpressing notifications
    return;
  }

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


- (NSArray*) buildFileItemPathFromIndex: (int) start toIndex: (int) end
               usingArray: (NSMutableArray *)array; {
  [array removeAllObjects];

  unsigned  i = start;
  while (i <= end) {
    if (![[path objectAtIndex:i] isVirtual]) {
      [array addObject: [path objectAtIndex:i]];
    }
    i++;
  }
  
  return array;
}


- (BOOL) extendVisiblePathToFileItem: (FileItem *)target 
           similar: (BOOL) similar {
  NSAssert(!visiblePathLocked, @"Cannot extend path when locked.");
  
  Item  *pathEndPoint = [path lastObject];
  if ([pathEndPoint isVirtual] || 
      ! [((FileItem *)pathEndPoint) isDirectory]) {
    // Can only extend from a DirectoryItem
    return NO;
  }
  
  Item  *contents = [((DirectoryItem *)pathEndPoint) getContents];
  if (contents == nil ||
      ! [self extendVisiblePathToFileItem: target similar: similar
                fromItem: contents] ) {
    // Failed to find a similar file item
    return NO;
  }
  
  NSAssert(! [[path lastObject] isVirtual], @"Unexpected virtual endpoint.");
  lastFileItemIndex = [path count] - 1;

  return YES;
}

- (BOOL) extendVisiblePathToFileItem: (FileItem *)target 
           similar: (BOOL) similar fromItem: (Item *)current {
  NSAssert(current != nil, @"current cannot be nil.");
           
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
              [fileItem isDirectory] == [target isDirectory] &&
              [fileItem isPhysical] == [target isPhysical]))) {
      return YES;
    }
  }
  
  // Item not found in this part of the tree, so back-track.
  [path removeLastObject];
  
  return NO;
}

@end
