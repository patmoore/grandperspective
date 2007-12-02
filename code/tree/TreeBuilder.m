#import "TreeBuilder.h"

#import "CompoundItem.h"
#import "DirectoryItem.h" // Also imports FileItem.h
#import "TreeBalancer.h"
#import "ItemInventory.h"


NSString  *LogicalFileSize = @"logical";
NSString  *PhysicalFileSize = @"physical";

NSString  *FreeSpace = @"free";
NSString  *UsedSpace = @"used";
NSString  *MiscUsedSpace = @"misc used";


/* Set the bulk request size so that bulkCatalogInfo fits in exactly four VM 
 * pages. This is a good balance between the iteration I/O overhead and the 
 * risk of incurring additional I/O from additional memory allocation.
 *
 * (Source: Code derived from source code of Disk Inventory X by Tjark Derlien.
 *  This particular bit of code contributed by Dave Payne from Apple?)
 */
#define BULK_CATALOG_REQUEST_SIZE  ( (4096 * 16) / ( sizeof(FSCatalogInfo) + \
                                                     sizeof(FSRef) + \
                                                     sizeof(HFSUniStr255) ) )
#define CATALOG_INFO_BITMAP  ( kFSCatInfoNodeFlags | \
                               kFSCatInfoDataSizes | \
                               kFSCatInfoRsrcSizes )

// TODO: Don't make global?
static struct {
    FSCatalogInfo  catalogInfoArray[BULK_CATALOG_REQUEST_SIZE];
	FSRef          fsRefArray[BULK_CATALOG_REQUEST_SIZE];
	HFSUniStr255   namesArray[BULK_CATALOG_REQUEST_SIZE];
} bulkCatalogInfo;


@interface TreeBuilder (PrivateMethods)

- (BOOL) buildTreeForDirectory:(DirectoryItem*)dirItem 
           parentPath:(NSString*)parentPath ref:(FSRef*)ref;

@end // @interface TreeBuilder (PrivateMethods)


@interface FSRefObject : NSObject {
@public
  FSRef  ref;
}

- (id) initWithFSRef:(FSRef*)ref;

@end // @interface FSRefObject


@implementation FSRefObject

// Overrides super's designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithFSRef instead.");
}

- (id) initWithFSRef:(FSRef*)refVal {
  if (self = [super init]) {
    ref = *refVal;
  }

  return self;
}

@end // @implementation FSRefObject


@implementation TreeBuilder

- (id) init {
  if (self = [super init]) {
    treeBalancer = [[TreeBalancer alloc] init];
    abort = NO;

    [self setFileSizeMeasure: LogicalFileSize];
  }
  return self;
}


- (void) dealloc {
  [treeBalancer release];
  [fileSizeMeasure release];
  
  [super dealloc];
}


- (NSString *) fileSizeMeasure {
  return fileSizeMeasure;
}

- (void) setFileSizeMeasure: (NSString *)measure {
  if ([measure isEqualToString: LogicalFileSize]) {
    useLogicalFileSize = YES;
  }
  else if ([measure isEqualToString: PhysicalFileSize]) {
    useLogicalFileSize = NO;
  }
  else {
    NSAssert(NO, @"Invalid file size measure.");
  }
  
  fileSizeMeasure = [measure retain];
}


- (void) abort {
  abort = YES;
}


- (DirectoryItem*) buildVolumeTreeForPath:(NSString *)path {
  FSRef  pathRef;
  Boolean  isDir;

  OSStatus  status = 
    FSPathMakeRef( [path fileSystemRepresentation], &pathRef, &isDir );
  NSAssert(isDir, @"Path is not a directory.");
  
  NSFileManager  *manager = [NSFileManager defaultManager];
  NSDictionary  *fsattrs = [manager fileSystemAttributesAtPath: path];
  
  unsigned long long  freeSpace = 
    [[fsattrs objectForKey: NSFileSystemFreeSize] unsignedLongLongValue];
  unsigned long long  volumeSize =
    [[fsattrs objectForKey: NSFileSystemSize] unsignedLongLongValue];
  
  // Establish the root of the volume
  unsigned long long  fileSystemNumber =
    [[fsattrs objectForKey: NSFileSystemNumber] unsignedLongLongValue];
  NSString  *pathToVolume = path;

  while (YES) {
    NSString  *parentPath = [pathToVolume stringByDeletingLastPathComponent];
    if ([parentPath isEqualToString: pathToVolume]) {
      break;
    }
    fsattrs = [manager fileSystemAttributesAtPath: parentPath];

    unsigned long long  parentFileSystemNumber =
      [[fsattrs objectForKey: NSFileSystemNumber] unsignedLongLongValue];
    if (parentFileSystemNumber != fileSystemNumber) {
      break;
    } 
    pathToVolume = parentPath;
  }
  NSLog(@"Volume: %@ [%@]", pathToVolume, 
           [manager displayNameAtPath: pathToVolume]);
  NSString  *relativePath =
    ([pathToVolume length] < [path length] ? 
       [path substringFromIndex: [pathToVolume length]] : @"");
  NSLog(@"Relative folder: %@", relativePath);  
       
  DirectoryItem*  scanTree = 
    [TreeBuilder scanTreeWithPath: relativePath volumePath: pathToVolume];
    
  if (! [self buildTreeForDirectory: scanTree parentPath: pathToVolume
                ref: &pathRef]) {
    return nil;
  }

  DirectoryItem*  volumeTree = 
    [TreeBuilder finaliseVolumeTreeForScanTree: scanTree
                   volumeSize: volumeSize freeSpace: freeSpace];

  return volumeTree;
}


+ (DirectoryItem *) scanTreeWithPath: (NSString *)relativePath
                      volumePath: (NSString *)pathToVolume {
  DirectoryItem*  volumeItem = 
    [[[DirectoryItem alloc] initWithName: pathToVolume parent: nil] 
         autorelease];
         
  DirectoryItem*  usedSpaceItem =
    [DirectoryItem specialDirectoryItemWithName: UsedSpace parent: volumeItem];
                     
  DirectoryItem*  scanTreeItem = 
    [[[DirectoryItem alloc] initWithName: relativePath parent: usedSpaceItem] 
         autorelease];
         
  return scanTreeItem;
  // Note: volumeItem and useSpacedItem are currently only retained in the
  // autorelease pool.
}

+ (DirectoryItem *) finaliseVolumeTreeForScanTree: (DirectoryItem *)scanTree
                      volumeSize: (unsigned long long) volumeSize 
                      freeSpace: (unsigned long long) freeSpace {
  DirectoryItem*  usedSpaceItem = [scanTree parentDirectory];
  DirectoryItem*  volumeTree = [usedSpaceItem parentDirectory];

  FileItem*  freeSpaceItem = 
    [FileItem specialFileItemWithName: FreeSpace parent: volumeTree 
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
    
  [volumeTree setDirectoryContents: 
                [CompoundItem compoundItemWithFirst: freeSpaceItem
                                second: usedSpaceItem]];
                                
  return volumeTree;
}


+ (unsigned long long) freeSpaceOfVolume: (DirectoryItem *)root {
  NSAssert([root parentDirectory]==nil, @"Root must be the volume tree.");
  
  return [[((CompoundItem *)[root getContents]) getFirst] itemSize];
}

+ (DirectoryItem *) scanTreeOfVolume: (DirectoryItem *)root {
  NSAssert([root parentDirectory]==nil, @"Root must be the volume tree.");
  
  return (DirectoryItem *)
           [((CompoundItem *)
             [((DirectoryItem *)
               [((CompoundItem *)
                 [root getContents]) getSecond]) getContents]) getSecond];
}

+ (DirectoryItem *) volumeOfFileItem: (FileItem *)item {
  // Climb to the top of the parent hierarchy; this is the volume (as long as
  // the item is indeed part of a volume tree).
  DirectoryItem  *parent;
  while (parent = [item parentDirectory]) {
    item = parent;
  }
  return (DirectoryItem *)item;
}

@end // @implementation TreeBuilder


@implementation TreeBuilder (PrivateMethods)

- (BOOL) buildTreeForDirectory:(DirectoryItem*)dirItem 
           parentPath:(NSString*)parentPath ref:(FSRef*)ref {

  ItemInventory  *itemInventory = [ItemInventory defaultItemInventory];

  NSMutableArray  *fileChildren = 
    [[NSMutableArray alloc] initWithCapacity:128];
  NSMutableArray  *dirChildren = 
    [[NSMutableArray alloc] initWithCapacity:32];
  NSMutableArray  *dirFsRefs = 
    [[NSMutableArray alloc] initWithCapacity:32];

  NSAutoreleasePool  *localAutoreleasePool = nil;
  
  NSString  *path = [parentPath stringByAppendingPathComponent:[dirItem name]];
  int  i;

  FSIterator iterator;
  OSStatus result = FSOpenIterator(ref, kFSIterateFlat, &iterator);

  if (result != noErr) {
    NSLog( @"Couldn't create FSIterator for '%@': Error %i", path, result);
  }
  else {

    while ( result == noErr && !abort ) {
      ItemCount actualCount = 0;
                
      result = FSGetCatalogInfoBulk( iterator,
                                     BULK_CATALOG_REQUEST_SIZE, &actualCount,
                                     NULL,
                                     CATALOG_INFO_BITMAP,
                                     bulkCatalogInfo.catalogInfoArray,
                                     bulkCatalogInfo.fsRefArray, NULL,
                                     bulkCatalogInfo.namesArray );
      
      if ( actualCount > 16 && localAutoreleasePool == nil) {
        localAutoreleasePool = [[NSAutoreleasePool alloc] init];
      }
      
      if (result == noErr || result == errFSNoMoreItems) {
        for (i = 0; i < actualCount; i++) {
          NSString *childName = 
            [[NSString alloc] initWithCharacters: 
                          (unichar *)&bulkCatalogInfo.namesArray[i].unicode
                          length: bulkCatalogInfo.namesArray[i].length];

          if (bulkCatalogInfo.catalogInfoArray[i].nodeFlags 
                & kFSNodeIsDirectoryMask) {
            // A directory node.

            DirectoryItem  *dirChildItem = 
              [[DirectoryItem alloc] initWithName:childName parent:dirItem];
              
            FSRefObject  *refObject = [[FSRefObject alloc] initWithFSRef:
                                          &(bulkCatalogInfo.fsRefArray[i])];

            [dirChildren addObject:dirChildItem];
            [dirFsRefs addObject:refObject];

            [dirChildItem release];
            [refObject release];
          }
          else {
            // A file node.
            
            ITEM_SIZE  childSize = 
              (useLogicalFileSize ? 
                (bulkCatalogInfo.catalogInfoArray[i].dataLogicalSize +
                 bulkCatalogInfo.catalogInfoArray[i].rsrcLogicalSize) :
                (bulkCatalogInfo.catalogInfoArray[i].dataPhysicalSize +
                 bulkCatalogInfo.catalogInfoArray[i].rsrcPhysicalSize));
      
            FileItem  *fileChildItem =
              [[FileItem alloc] initWithName:childName parent:dirItem 
                                  size:childSize];

            [fileChildren addObject:fileChildItem];
            [fileChildItem release];

            [itemInventory registerFileItem: fileChildItem];
          }
          
          [childName release];
        }
      }
    }
    FSCloseIterator(iterator);
  }

  for (i = [dirFsRefs count]; --i >= 0 && !abort; ) {
    DirectoryItem  *dirChildItem = [dirChildren objectAtIndex:i];
    FSRefObject  *refObject = [dirFsRefs objectAtIndex:i];
    
    [self buildTreeForDirectory:dirChildItem parentPath:path
            ref: &(refObject->ref)];
  }
  
  Item  *fileTree = [treeBalancer createTreeForItems:fileChildren];
  Item  *dirTree = [treeBalancer createTreeForItems:dirChildren];
  Item  *contentTree = [CompoundItem compoundItemWithFirst: fileTree 
                                       second: dirTree];

  [dirItem setDirectoryContents: contentTree];
  
  [fileChildren release];
  [dirChildren release];
  [dirFsRefs release];

  [localAutoreleasePool release];
  
  return !abort;
}

@end // @implementation TreeBuilder (PrivateMethods)
