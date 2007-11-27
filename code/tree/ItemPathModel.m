#import "ItemPathModel.h"

#import "CompoundItem.h"
#import "DirectoryItem.h" // Imports FileItem.h


@interface ItemPathModel (PrivateMethods)

- (void) postSelectedItemChanged;
- (void) postVisibleTreeChanged;
- (void) postVisiblePathLockingChanged;

// "start" and "end" are both inclusive.
- (NSArray*) buildFileItemPathFromIndex:(int)start toIndex:(int)end;

- (BOOL) extendPathToFileItemWithName:(NSString*)name fromItem:(Item*)item;

@end


@implementation ItemPathModel

// Overrides super's designated initialiser.
- (id) init {
  NSAssert(NO, @"Use -initWithTree instead.");
}

- (id) initWithTree:(DirectoryItem*)itemTreeRoot {
  if (self = [super init]) {
    path = [[NSMutableArray alloc] initWithCapacity:64];

    [path addObject:itemTreeRoot];

    visibleTreeRootIndex = 0;
    selectedFileItemIndex = 0;
    lastFileItemIndex = 0;
    
    visiblePathLocked = NO;
    lastNotifiedSelectedFileItemIndex = -1;
  }
  return self;
}

- (void) dealloc {
  //NSLog(@"ItemPathModel-dealloc");

  [path release];
  
  [super dealloc];
}

- (id) copyWithZone:(NSZone*) zone {
  ItemPathModel  *copy = 
    [[[self class] allocWithZone:zone] initWithTree: [self scanTree]];
    
  [copy->path removeAllObjects];
  [copy->path addObjectsFromArray:path];

  copy->visibleTreeRootIndex = visibleTreeRootIndex;
  copy->selectedFileItemIndex = selectedFileItemIndex;
  copy->lastFileItemIndex = lastFileItemIndex;
  copy->visiblePathLocked = visiblePathLocked;
  copy->lastNotifiedSelectedFileItemIndex = -1;
  
  return copy;
}


- (NSArray*) invisibleFileItemPath {
  return [self buildFileItemPathFromIndex: 0 toIndex: visibleTreeRootIndex];
}

- (NSArray*) visibleSelectedFileItemPath {
  return [self buildFileItemPathFromIndex: visibleTreeRootIndex + 1 
                 toIndex: selectedFileItemIndex ];
}

- (NSArray*) visibleFileItemPath {
  return [self buildFileItemPathFromIndex: visibleTreeRootIndex + 1 
                 toIndex: lastFileItemIndex ];
}


- (NSArray*) itemPath {
  // Note: For efficiency returning path directly, instead of an (immutable)
  // copy. This is done so that there is not too much overhead associated
  // with invoking ItemPathDrawer -drawItemPath:...: many times in short
  // successsion.
  return path;
}

- (NSArray*) itemPathToSelectedFileItem {
   return [path subarrayWithRange:NSMakeRange(0, selectedFileItemIndex + 1)];
}


- (DirectoryItem*) scanTree {
  return [path objectAtIndex: 0];
}

- (FileItem*) visibleTree {
  return [path objectAtIndex: visibleTreeRootIndex];
}

- (FileItem*) selectedFileItem {
  return [path objectAtIndex: selectedFileItemIndex];
}

- (FileItem*) fileItemPathEndPoint {
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
    [self postSelectedItemChanged];
    
    return YES;
  }

  return NO;
}


- (void) extendVisiblePath: (Item *)nextItem {
  NSAssert(!visiblePathLocked, @"Cannot extend path when locked.");
  
  [path addObject: nextItem];  
  
  if (! [nextItem isVirtual]) {
    lastFileItemIndex = [path count] - 1;
    
    // Automatically update the selection to the end point.
    selectedFileItemIndex = lastFileItemIndex;
    [self postSelectedItemChanged];
  }
}


- (BOOL) extendVisiblePathToFileItemWithName: (NSString *)name {
  NSAssert(!visiblePathLocked, @"Cannot extend path when locked.");
  
  id  pathEndPoint = [path lastObject];
  
  if ([pathEndPoint isVirtual] || [pathEndPoint isPlainFile]) {
    // Can only extend from a DirectoryItem
    return NO;
  }
  
  DirectoryItem  *dirItem = (DirectoryItem*)pathEndPoint;
  
  if (! [self extendPathToFileItemWithName: name 
                fromItem: [dirItem getContents]] ) {
    // Failed to find a file item with the given name.
    return NO;
  }
  
  NSAssert(![[path lastObject] isVirtual], @"Unexpected virtual endpoint.");
  lastFileItemIndex = [path count] - 1;

  // Automatically update the selection to the end point.
  selectedFileItemIndex = lastFileItemIndex;
  [self postSelectedItemChanged];
  
  return YES;
}


- (BOOL) canMoveTreeViewUp {
  return (visibleTreeRootIndex > 0);
}

- (BOOL) canMoveTreeViewDown {
  return (visibleTreeRootIndex < lastFileItemIndex);
}

- (void) moveTreeViewUp {
  NSAssert([self canMoveTreeViewUp], @"Cannot move up.");

  do {
    visibleTreeRootIndex--;
  } while ([[path objectAtIndex:visibleTreeRootIndex] isVirtual]);
  
  [self postVisibleTreeChanged];
}

- (void) moveTreeViewDown {
  NSAssert([self canMoveTreeViewDown], @"Cannot move down.");

  do {
    visibleTreeRootIndex++;
  } while ([[path objectAtIndex:visibleTreeRootIndex] isVirtual]);
  
  if (selectedFileItemIndex < visibleTreeRootIndex) {
    // Ensure that the selected file item is always in the visible path
    selectedFileItemIndex = visibleTreeRootIndex;
    [self postSelectedItemChanged];
  }

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
  
  do {
    selectedFileItemIndex--;
  } while ([[path objectAtIndex: selectedFileItemIndex] isVirtual]);
  
  [self postSelectedItemChanged];
}

- (void) moveSelectionDown {
  NSAssert([self canMoveSelectionDown], @"Cannot move down");
  
  do {
    selectedFileItemIndex++;
  } while ([[path objectAtIndex: selectedFileItemIndex] isVirtual]);
  
  [self postSelectedItemChanged];
}

@end


@implementation ItemPathModel (PrivateMethods)

- (void) postSelectedItemChanged {
  if (lastNotifiedSelectedFileItemIndex == -1) {
    // Currently surpressing notifications
  }

  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"selectedItemChanged" object:self];
}

- (void) postVisibleTreeChanged {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"visibleTreeChanged" object:self];
}

- (void) postVisiblePathLockingChanged {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"visiblePathLockingChanged" object:self];
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


- (BOOL) extendPathToFileItemWithName:(NSString*)name fromItem:(Item*)item {
  [path addObject:item];
  
  if ([item isVirtual]) {
    CompoundItem  *compoundItem = (CompoundItem*)item;
    
    if ([self extendPathToFileItemWithName:name 
                fromItem:[compoundItem getFirst]]) {
      return YES;  
    }
    if ([self extendPathToFileItemWithName:name 
                fromItem:[compoundItem getSecond]]) {
      return YES;
    }
  }
  else {
    FileItem  *fileItem = (FileItem*)item;
    
    if ([[fileItem name] isEqualToString:name]) {
      return YES;
    }
  }
  
  // Item not found in this part of the tree, so back-track.
  [path removeLastObject];
  
  return NO;
}

@end