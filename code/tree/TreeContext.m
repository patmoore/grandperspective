#import "TreeContext.h"

#import "CompoundAndItemTest.h"
#import "DirectoryItem.h"
#import "CompoundItem.h"


NSString  *FreeSpace = @"free";
NSString  *UsedSpace = @"used";
NSString  *MiscUsedSpace = @"misc used";


static int  nextFilterId = 1;


@interface TreeContext (PrivateMethods)

- (id) initWithVolumePath: (NSString *)volumePath
         scanPath: (NSString *)relativeScanPath
         fileSizeMeasure: (NSString *)fileSizeMeasure
         volumeSize: (unsigned long long) volumeSize
         freeSpace: (unsigned long long) freeSpace
         scanTime: (NSDate *)scanTime
         filter: (NSObject <FileItemTest> *)filter
         filterId: (int) filterId;

// First helper method for creating a new volume tree structure. Once the
// tree skeleton has been created, the contents of the scan tree should be
// set. After this has been done, the skeleton should be finalised by
// calling -finaliseTreeSkeleton.
- (void) createTreeSkeletonWithVolumePath: (NSString *)volumePath
           scanPath: (NSString *)relativeScanPath;

// Second helper method for creating a new volume tree structure. Only after
// calling this method is the volume tree ready for use.
- (void) finaliseTreeSkeleton;

// In between creating the skeleton and finalising it, there is some temporary
// retain-count magic to prevent the skeleton from falling apart. This is
// undone by calling this method.
//
// Note: It can safely be called after the skeleton has been finalised, in 
// which case it will not do anything.
- (void) emptyCloset;

@end


@implementation TreeContext

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithVolumePath:scanPath:fileSizeMeasure:... instead.");
}


- (id) initWithVolumePath: (NSString *)volumePath
         scanPath: (NSString *)relativeScanPath
         fileSizeMeasure: (NSString *)fileSizeMeasureVal
         volumeSize: (unsigned long long) volumeSizeVal 
         freeSpace: (unsigned long long) freeSpaceVal {
  return [self initWithVolumePath: volumePath
                 scanPath: relativeScanPath
                 fileSizeMeasure: fileSizeMeasureVal
                 volumeSize: volumeSizeVal 
                 freeSpace: freeSpaceVal 
                 scanTime: [NSDate date]
                 filter: nil 
                 filterId: 0];
}


- (void) dealloc {
  [self emptyCloset];

  [scanTree release];
  [volumeTree release];
  [fileSizeMeasure release];
  [scanTime release];
  [filter release];

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
                                 scanPath: [scanTree name]
                                 fileSizeMeasure: fileSizeMeasure
                                 volumeSize: volumeSize
                                 freeSpace: freeSpace
                                 scanTime: scanTime
                                 filter: totalFilter
                                 filterId: nextFilterId++] autorelease];
}


- (void) postInit {
  [self finaliseTreeSkeleton];
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

- (NSString*) fileSizeMeasure {
  return fileSizeMeasure;
}

- (NSDate*) scanTime {
  return scanTime;
}

- (NSObject <FileItemTest>*) fileItemFilter {
  return filter;
}

- (int) filterIdentifier {
  return filterId;
}

- (NSString*) filterName {
  if (filterId == 0) {
    // There is no filter
    return NSLocalizedString( @"None", 
                              @"The filter name when there is no filter." );
  }
  else {
    NSString  *format = NSLocalizedString( @"Filter%d", 
                                           @"Filter naming template." );
    return [NSString stringWithFormat: format, filterId];
  }
}

@end // TreeContext


@implementation TreeContext (PrivateMethods)

- (id) initWithVolumePath: (NSString *)volumePath
         scanPath: (NSString *)relativeScanPath
         fileSizeMeasure: (NSString *)fileSizeMeasureVal
         volumeSize: (unsigned long long) volumeSizeVal 
         freeSpace: (unsigned long long) freeSpaceVal
         scanTime: (NSDate *)scanTimeVal
         filter: (NSObject <FileItemTest> *)filterVal
         filterId: (int) filterIdVal {
  if (self = [super init]) {
    [self createTreeSkeletonWithVolumePath: volumePath 
            scanPath: relativeScanPath];

    fileSizeMeasure = [fileSizeMeasureVal retain];
    volumeSize = volumeSizeVal;
    freeSpace = freeSpaceVal;
    
    scanTime = [scanTimeVal retain];

    filter = [filterVal retain];
    filterId = filterIdVal;
  }
  
  return self;
}


- (void) createTreeSkeletonWithVolumePath: (NSString *)volumePath
           scanPath: (NSString *)relativeScanPath {
  NSAssert(scanTree == nil, @"scanTree should be nil.");

  // Note: Not using volumeTree member variable until the tree has been
  // fully set up (so that volumeTree always stores a finalised tree).
  DirectoryItem*  volumeItem = 
    [[DirectoryItem alloc] initWithName: volumePath parent: nil];
         
  DirectoryItem*  usedSpaceItem =
    [[DirectoryItem specialDirectoryItemWithName: UsedSpace 
                      parent: volumeItem] retain];
                     
  scanTree = [[DirectoryItem alloc] initWithName: relativeScanPath 
                                      parent: usedSpaceItem];

  // Note: volumeItem and useSpacedItem are temporarily retained, to prevent 
  // them from being autoreleased, even though TreeContext instance does not 
  // own either. This temporary retain-count boost is undone when the tree 
  // skeleton is finalised.
}


- (void) finaliseTreeSkeleton {
  NSAssert(scanTree != nil, @"scanTree should not be nil.");
  NSAssert(volumeTree == nil, @"volumeTree should be nil.");

  DirectoryItem*  usedSpaceItem = [scanTree parentDirectory];
  DirectoryItem*  volumeItem = [usedSpaceItem parentDirectory];

  FileItem*  freeSpaceItem = 
    [FileItem specialFileItemWithName: FreeSpace parent: volumeItem 
                size: freeSpace];
                 
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
    [FileItem specialFileItemWithName: MiscUsedSpace parent: usedSpaceItem
                size: miscUnusedSize];

  [usedSpaceItem setDirectoryContents: 
                   [CompoundItem compoundItemWithFirst: miscUnusedSpaceItem
                                   second: scanTree]];
    
  [volumeItem setDirectoryContents: 
                [CompoundItem compoundItemWithFirst: freeSpaceItem
                                second: usedSpaceItem]];
  
  [volumeItem retain];
  
  [self emptyCloset];
  
  volumeTree = volumeItem;
}


- (void) emptyCloset {
  if (scanTree == nil) {
    // There's no tree skeleton
    return;
  }
  if (volumeTree != nil) {
    // The skeleton has been finalised already, which implies that the closet
    // has already been emptied.
    return;
  }

  // Okay, empty the closet.
  DirectoryItem*  usedSpaceItem = [scanTree parentDirectory];
  DirectoryItem*  volumeItem = [usedSpaceItem parentDirectory];

  [usedSpaceItem release];
  [volumeItem release];
}

@end // TreeContext (PrivateMethods)

