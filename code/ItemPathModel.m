#import "ItemPathModel.h"


#import "FileItem.h"


@interface ItemPathModel (PrivateMethods)

- (void) postVisibleItemPathChanged;
- (void) postVisibleItemTreeChanged;
- (void) postVisibleItemPathLockingChanged;

// "start" is inclusive, "end" is exclusive.
- (NSString*) buildPathNameFromIndex:(int)start toIndex:(int)end;

@end


@implementation ItemPathModel

// Overrides super's designated initialiser.
- (id) init {
  NSAssert(NO, @"Use -initWithTree instead.");
}

- (id) initWithTree:(FileItem*)itemTreeRoot {
  if (self = [super init]) {
    path = [[NSMutableArray alloc] initWithCapacity:64];

    [path addObject:itemTreeRoot];

    visibleTreeRootIndex = 0;
    lastFileItemIndex = 0;
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
    [[[self class] allocWithZone:zone] initWithTree:[self itemTree]];
    
  [copy->path removeAllObjects];
  [copy->path addObjectsFromArray:path];

  copy->visibleTreeRootIndex = visibleTreeRootIndex;
  copy->lastFileItemIndex = lastFileItemIndex;
  copy->visibleItemPathLocked = visibleItemPathLocked;
  
  return copy;
}


- (NSArray*) invisibleFileItemPath {
  NSMutableArray  *invisible = [NSMutableArray arrayWithCapacity:8];

  int  i = 0;
  while (i <= visibleTreeRootIndex) {
    if (![[path objectAtIndex:i] isVirtual]) {
      [invisible addObject:[path objectAtIndex:i]];
    }
    i++;
  }
  
  return invisible;
}

- (NSArray*) visibleFileItemPath {
  NSMutableArray  *visible = [NSMutableArray arrayWithCapacity:8];

  int  i = visibleTreeRootIndex + 1, max = [path count];
  while (i < max) {
    if (![[path objectAtIndex:i] isVirtual]) {
      [visible addObject:[path objectAtIndex:i]];
    }
    i++;
  }
  return visible;
}


- (NSArray*) invisibleItemPath {
  return [path subarrayWithRange:NSMakeRange(0, visibleTreeRootIndex + 1)];
}


- (NSArray*) visibleItemPath {
  return [path subarrayWithRange:
                 NSMakeRange(visibleTreeRootIndex + 1,
                             [path count] - visibleTreeRootIndex - 1)];
}


- (NSArray*) itemPath {
  // Note: For efficiency returning path directly, instead of an (immutable)
  // copy. This is done so that there is not too much overhead associated
  // with invoking ItemPathDrawer -drawItemPath:...: many times in short
  // successsion.
  return path;
}


- (FileItem*) fileItemPathEndPoint {
  return [path objectAtIndex:lastFileItemIndex];
}



- (NSString*) rootFilePathName {
  FileItem  *root = [path objectAtIndex:0];
  return [root name];
}

- (NSString*) invisibleFilePathName {
  return [self buildPathNameFromIndex:1             // skip the tree root
                 toIndex:visibleTreeRootIndex + 1]; // include visible root
}

- (NSString*) visibleFilePathName {
  return [self buildPathNameFromIndex:visibleTreeRootIndex + 1  
                                                     // skip the visible root
                  toIndex:[path count]];             // include the end point
}


- (BOOL) isVisibleItemPathLocked {
  return visibleItemPathLocked;
}

- (void) setVisibleItemPathLocking:(BOOL)value {
  if (value == visibleItemPathLocked) {
    return; // No change: Ignore.
  }
  
  visibleItemPathLocked = value;
  [self postVisibleItemPathLockingChanged];
}


- (void) suppressItemPathChangedNotifications:(BOOL)option {
  if (option) {
    if (lastNotifiedPathEndPoint != nil) {
      return; // Already suppressing notifications.
    }
    lastNotifiedPathEndPoint = [path lastObject];
  }
  else {
    if (lastNotifiedPathEndPoint == nil) {
      return; // Already instantanously generating notifications.
    }
    
    if (lastNotifiedPathEndPoint != [path lastObject]) {
      [self postVisibleItemPathChanged];
    }
    lastNotifiedPathEndPoint = nil;
  }
}

- (BOOL) clearVisibleItemPath {
  NSAssert(!visibleItemPathLocked, @"Cannot change path when locked.");
  
  int  num = [path count] - visibleTreeRootIndex - 1;

  if (num > 0) {
    [path removeObjectsInRange:NSMakeRange(visibleTreeRootIndex + 1, num)];
    lastFileItemIndex = visibleTreeRootIndex;

    if (lastNotifiedPathEndPoint == nil) { // Notifications not suppressed.
      [self postVisibleItemPathChanged];
    }
    
    return YES;
  }

  return NO;
}


- (void) extendVisibleItemPath:(Item*)nextItem {
  NSAssert(!visibleItemPathLocked, @"Cannot change path when locked.");
  
  if (! [nextItem isVirtual]) {
    lastFileItemIndex = [path count];
  }
  
  [path addObject:nextItem];
  
  if (lastNotifiedPathEndPoint == nil) { // Notifications not suppressed.
    [self postVisibleItemPathChanged];
  }
}


- (FileItem*) itemTree {
  return [path objectAtIndex:0];
}

- (FileItem*) visibleItemTree {
  return [path objectAtIndex:visibleTreeRootIndex];
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
  
  [self postVisibleItemTreeChanged];
}

- (void) moveTreeViewDown {
  NSAssert([self canMoveTreeViewDown], @"Cannot move down.");

  do {
    visibleTreeRootIndex++;
  } while ([[path objectAtIndex:visibleTreeRootIndex] isVirtual]);  

  [self postVisibleItemTreeChanged];
}

@end


@implementation ItemPathModel (PrivateMethods)

- (void) postVisibleItemPathChanged {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"visibleItemPathChanged" object:self];
}

- (void) postVisibleItemTreeChanged {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"visibleItemTreeChanged" object:self];
}

- (void) postVisibleItemPathLockingChanged {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"visibleItemPathLockingChanged" object:self];
}

- (NSString*) buildPathNameFromIndex:(int)start toIndex:(int)end {
  NSMutableString  *s = 
    [[[NSMutableString alloc] initWithCapacity:128] autorelease];

  int  i = start; // Skip the root
  while (i < end) {
    Item*  item = [path objectAtIndex:i]; 

    if (![item isVirtual]) {
      if ([s length] > 0) {
        [s appendString:@"/"];
      }
      
      id  fileitem = item;
      [s appendString:[fileitem name]];
    }
    i++;
  }

  // Return an immutable string.
  return  [NSString stringWithString:s];
}

@end