#import "TreeContext.h"

#import "CompoundAndItemTest.h"
#import "DirectoryItem.h"
#import "CompoundItem.h"
#import "ItemPathModel.h"
#import "ItemPathModelView.h"


NSString  *FreeSpace = @"free";
NSString  *UsedSpace = @"used";
NSString  *MiscUsedSpace = @"misc used";
NSString  *FreedSpace = @"freed";

NSString  *FileItemDeletedEvent = @"fileItemDeleted";
NSString  *FileItemDeletedHandledEvent = @"fileItemDeletedHandled";


#define IDLE      100
#define READING   101
#define WRITING   102


@interface TreeContext (PrivateMethods)

/* Returns the item that owns the selected file item, i.e. the one directly
 * above it in the tree. This can be a virtual item.
 */
- (Item *) itemContainingSelectedFileItem: (ItemPathModelView *)pathModelView;

// Signals that an item in the tree has been replaced (by another one, of the
// same size). The item itself is not part of the notification, but can be 
// recognized because its parent directory has been cleared.
- (void) postFileItemDeleted;
- (void) fileItemDeletedHandled: (NSNotification *)notification;

// Recursively calculates the total size of all plain files inside the given
// item. It excludes "special" file item so that already freed space is not
// taken into account. This is required to accurately keep track of the total
// freed space.
- (ITEM_SIZE) totalPlainFileSize: (Item *)item;

@end


@implementation TreeContext

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithVolumePath:scanPath:fileSizeMeasure:... instead.");
}


- (id) initWithVolumePath: (NSString *)volumePath
         fileSizeMeasure: (NSString *)fileSizeMeasureVal
         volumeSize: (unsigned long long) volumeSizeVal 
         freeSpace: (unsigned long long) freeSpaceVal
         filter: (NSObject <FileItemTest> *)filterVal {
  return [self initWithVolumePath: volumePath
                 fileSizeMeasure: fileSizeMeasureVal
                 volumeSize: volumeSizeVal 
                 freeSpace: freeSpaceVal
                 filter: filterVal 
                 scanTime: [NSDate date]];
}

- (id) initWithVolumePath: (NSString *)volumePath
         fileSizeMeasure: (NSString *)fileSizeMeasureVal
         volumeSize: (unsigned long long) volumeSizeVal 
         freeSpace: (unsigned long long) freeSpaceVal
         filter: (NSObject <FileItemTest> *)filterVal
         scanTime: (NSDate *)scanTimeVal {
  if (self = [super init]) {
    volumeTree = [[DirectoryItem alloc] initWithName: volumePath parent: nil];
    usedSpaceItem = [[DirectoryItem alloc] initWithName: UsedSpace 
                                             parent: volumeTree
                                             flags: FILE_IS_SPECIAL];
                                             
    fileSizeMeasure = [fileSizeMeasureVal retain];
    volumeSize = volumeSizeVal;
    freeSpace = freeSpaceVal;
    freedSpace = 0;
    
    scanTime = [scanTimeVal retain];

    filter = [filterVal retain];

    // Listen to self
    [[NSNotificationCenter defaultCenter] 
        addObserver: self selector: @selector(fileItemDeletedHandled:)
        name: FileItemDeletedHandledEvent object: self];
        
    mutex = [[NSLock alloc] init];
    lock = [[NSConditionLock alloc] initWithCondition: IDLE];
    numReaders = 0;
    numWaitingReaders = 0;
    numWaitingWriters = 0;
  }
  
  return self;
}


- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver: self];

  [volumeTree release];
  [usedSpaceItem release];
  [scanTree release];
  
  [fileSizeMeasure release];
  [scanTime release];
  [filter release];
  
  [replacedItem release];
  [replacingItem release];
  
  [mutex release];
  [lock release];

  [super dealloc];
}


- (TreeContext *) contextAfterFiltering: (NSObject <FileItemTest> *)newFilter {
  NSAssert(newFilter!=nil, @"Filter should not be nil.");

  NSObject <FileItemTest>  *totalFilter = nil;
  if (filter == nil) {
    totalFilter = newFilter;
  }
  else {
    totalFilter = 
      [[[CompoundAndItemTest alloc] initWithSubItemTests:
           [NSArray arrayWithObjects:filter, newFilter, nil]] autorelease];
  }

  return [[[TreeContext alloc] initWithVolumePath: [volumeTree name]
                                 fileSizeMeasure: fileSizeMeasure
                                 volumeSize: volumeSize
                                 freeSpace: freeSpace
                                 filter: totalFilter
                                 scanTime: scanTime] autorelease];
}


- (void) setScanTree: (DirectoryItem *)scanTreeVal {
  NSAssert(scanTree == nil, @"scanTree should be nil.");
  NSAssert([scanTreeVal parentDirectory] == [self scanTreeParent], 
             @"Invalid parent.");

  scanTree = [scanTreeVal retain];

  FileItem*  freeSpaceItem = 
    [[[FileItem alloc] initWithName: FreeSpace 
                         parent: volumeTree 
                         size: freeSpace
                         flags: FILE_IS_SPECIAL] autorelease];
                 
  ITEM_SIZE  miscUnusedSize = volumeSize;
  if ([scanTree itemSize] <= volumeSize) {
    miscUnusedSize -= [scanTree itemSize];
    
    if (freeSpace <= volumeSize) {
      miscUnusedSize -= freeSpace;
    }
    else {
      NSLog(@"Scanned tree size plus free space is larger than volume size.");
      miscUnusedSize = 0;
    }
  } 
  else {
    NSLog(@"Scanned tree size is larger than volume size.");
    miscUnusedSize = 0;
  }

  FileItem*  miscUnusedSpaceItem = 
    [[[FileItem alloc] initWithName: MiscUsedSpace 
                         parent: usedSpaceItem
                         size: miscUnusedSize
                         flags: FILE_IS_SPECIAL] autorelease];

  [usedSpaceItem setDirectoryContents: 
                   [CompoundItem compoundItemWithFirst: miscUnusedSpaceItem
                                   second: scanTree]];
    
  [volumeTree setDirectoryContents: 
                [CompoundItem compoundItemWithFirst: freeSpaceItem
                                second: usedSpaceItem]];
}


- (DirectoryItem *) scanTreeParent {
  return usedSpaceItem;
}

- (DirectoryItem*) volumeTree {
  return volumeTree;
}

- (DirectoryItem*) scanTree {
  return scanTree;
}

- (unsigned long long) volumeSize {
  return volumeSize;
}

- (unsigned long long) freeSpace {
  return freeSpace;
}

- (unsigned long long) freedSpace {
  return freedSpace;
}

- (NSString*) fileSizeMeasure {
  return fileSizeMeasure;
}

- (NSDate*) scanTime {
  return scanTime;
}

- (NSObject <FileItemTest>*) fileItemFilter {
  return filter;
}


- (void) deleteSelectedFileItem: (ItemPathModelView *)pathModelView {
  NSAssert(replacedItem == nil, @"Replaced item not nil.");
  NSAssert(replacingItem == nil, @"Replacing item not nil.");
  
  replacedItem = [[pathModelView selectedFileItemInTree] retain];  
  replacingItem =
    [[FileItem alloc] initWithName: ( [replacedItem isHardLinked] 
                                      ? MiscUsedSpace : FreedSpace )
                        parent: [replacedItem parentDirectory] 
                        size: [replacedItem itemSize]
                        flags: FILE_IS_SPECIAL];
                                      
  Item  *containingItem = [self itemContainingSelectedFileItem: pathModelView];
  
  [self obtainWriteLock];
  if ([containingItem isVirtual]) {
    CompoundItem  *compoundItem = (CompoundItem *)containingItem;
    
    if ([compoundItem getFirst] == replacedItem) {
      [compoundItem replaceFirst: replacingItem];
    }
    else if ([compoundItem getSecond] == replacedItem) {
      [compoundItem replaceSecond: replacingItem];
    }
    else {
      NSAssert(NO, @"Selected item not found.");
    }
  } 
  else {
    DirectoryItem  *dirItem = (DirectoryItem *)containingItem;
  
    NSAssert([dirItem isDirectory], @"Expected a DirectoryItem.");
    NSAssert([dirItem getContents] == replacedItem, 
               @"Selected item not found.");
    
    [dirItem replaceDirectoryContents: replacingItem];
  }  
  [self releaseWriteLock];
  
  if (! [replacedItem isHardLinked]) {
    freedSpace += [self totalPlainFileSize: replacedItem];
  }
  else {
    // void. Do not increase the freed space. The item was hard-linked, which
    // means that at the time of scanning, there were multiple references to
    // the item. The free space will only increase when all references are
    // deleted. As only one is included in the tree, this cannot be done  
    // using only this tree.
  }

  [self postFileItemDeleted];
}

- (FileItem *) replacedFileItem {
  NSAssert(replacedItem != nil, @"replacedFileItem is nil.");
  return replacedItem;
}

- (FileItem *) replacingFileItem {
  NSAssert(replacingItem != nil, @"replacingFileItem is nil.");
  return replacingItem;
}


- (void) obtainReadLock {
  BOOL  wait = NO;

  [mutex lock];
  if (numReaders > 0) {
    // Already in READING state
    numReaders++;
  }
  else if ([lock tryLockWhenCondition: IDLE]) {
    // Was in IDLE state, start reading
    numReaders++;
    [lock unlockWithCondition: READING];
  }
  else {
    // Currently in WRITE state, so will have to wait.
    numWaitingReaders++;
    wait = YES;
  }
  [mutex unlock];
  
  if (wait) {
    [lock lockWhenCondition: READING];
    // We are now allowed to read.
   
    [mutex lock];
    numWaitingReaders--;
    numReaders++;
    [mutex unlock];
     
    // Give up lock, allowing other readers to wake up as well.
    [lock unlockWithCondition: READING];
  }
}

- (void) releaseReadLock {
  [mutex lock];
  numReaders--;
  
  if (numReaders == 0) {
    [lock lockWhenCondition: READING]; // Immediately succeeds.
    
    if (numWaitingReaders > 0) {
      // Although there is no need for waiting readers in the READING state,
      // this can happen if waiting readers are not woken up quickly enough.
      [lock unlockWithCondition: READING];
    }
    else if (numWaitingWriters > 0) {
      [lock unlockWithCondition: WRITING];
    }
    else {
      [lock unlockWithCondition: IDLE];
    }
  }
  
  [mutex unlock];
}

- (void) obtainWriteLock {
  BOOL  wait = NO;

  [mutex lock];
  if ([lock tryLockWhenCondition: IDLE]) {
    // Was in IDLE state, start writing
    
    // Note: Not releasing lock, to ensure that no other thread starts reading
    // or writing.
    
    // Note: Although the condition of the lock is still IDLE, that does not
    // matter as long as the lock is being held. The condition only matters 
    // when the is (being) unlocked. The TreeContext is now already considered 
    // to be in WRITING state.
  }
  else {
    // Currently in READING or WRITING state 
    numWaitingWriters++;
    wait = YES;
  }
  [mutex unlock];
  
  if (wait) {
    [lock lockWhenCondition: WRITING];
    // We are now in the WRITING state.
   
    [mutex lock];
    numWaitingWriters--;
    [mutex unlock];
    
    // Note: Not releasing lock, to ensure that no other thread starts reading
    // or writing.
  }
}

- (void) releaseWriteLock {
  [mutex lock];  

  if (numWaitingReaders > 0) {
    [lock unlockWithCondition: READING];
  }
  else if (numWaitingWriters > 0) {
    [lock unlockWithCondition: WRITING];
  }
  else {
    [lock unlockWithCondition: IDLE];
  }
  
  [mutex unlock];
}

@end // TreeContext


@implementation TreeContext (PrivateMethods)

- (Item *) itemContainingSelectedFileItem: (ItemPathModelView *)pathModelView {
  FileItem  *selectedItem = [pathModelView selectedFileItemInTree];
  
  // Get the items in the path (from the underlying path model). 
  NSArray  *itemsInPath = [[pathModelView pathModel] itemPath];
  int  i = [itemsInPath count] - 1;
  while ([itemsInPath objectAtIndex: i] != selectedItem) {
    NSAssert(i > 0, @"Item not found.");
    i--;
  }

  // Found the item. Return the one just above it in the path.  
  return [itemsInPath objectAtIndex: i-1];
}


- (void) postFileItemDeleted {
  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];

  [nc postNotificationName: FileItemDeletedEvent object: self];
  [nc postNotificationName: FileItemDeletedHandledEvent object: self];
}

- (void) fileItemDeletedHandled: (NSNotification *)notification {
  [replacedItem release];
  replacedItem = nil;
  
  [replacingItem release];
  replacingItem = nil;  
}

- (ITEM_SIZE) totalPlainFileSize: (Item *)item {
  if ( [item isVirtual] ) {
    return ( [self totalPlainFileSize: [((CompoundItem *)item) getFirst]] +
             [self totalPlainFileSize: [((CompoundItem *)item) getSecond]] );
  }
  else if ( [((FileItem *)item) isDirectory] ) {
    return [self totalPlainFileSize: [((DirectoryItem *)item) getContents]];
  }
  else {
    return [((FileItem *)item) isSpecial] ? 0 : [item itemSize];
  }
}

@end // TreeContext (PrivateMethods)

