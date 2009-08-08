#import "TreeBuilder.h"

#import "TreeConstants.h"
#import "CompoundItem.h"
#import "DirectoryItem.h"
#import "PlainFileItem.h"
#import "FilteredTreeGuide.h"
#import "TreeBalancer.h"
#import "TreeContext.h"

#import "ProgressTracker.h"
#import "UniformTypeInventory.h"


NSString  *LogicalFileSize = @"logical";
NSString  *PhysicalFileSize = @"physical";


NSString  *CouldNotEstablishSystemPath = @"CouldNotEstablishSystemPath";


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
                               kFSCatInfoRsrcSizes | \
                               kFSCatInfoCreateDate )

typedef struct  {
  FSCatalogInfo  catalogInfoArray[BULK_CATALOG_REQUEST_SIZE];
  FSRef          fileRefArray[BULK_CATALOG_REQUEST_SIZE];
  HFSUniStr255   namesArray[BULK_CATALOG_REQUEST_SIZE];
} BulkCatalogInfo;


ITEM_SIZE getLogicalFileSize(FSCatalogInfo *catalogInfo) {
  return (catalogInfo->dataLogicalSize + catalogInfo->rsrcLogicalSize);
}

ITEM_SIZE getPhysicalFileSize(FSCatalogInfo *catalogInfo) {
  return (catalogInfo->dataPhysicalSize + catalogInfo->rsrcPhysicalSize);
}


@interface TreeBuilder (PrivateMethods)

- (BOOL) buildTreeForDirectory: (DirectoryItem *)dirItem 
           fileRef: (FSRef *)fileRef parentPath: (NSString *)parentPath;
           
- (BOOL) includeItemForFileRef: (FSRef *)fileRef
           catalogInfo: (FSCatalogInfo *)catalogInfo
           systemPath: (NSString **)systemPath;

- (UInt8) flagsForFileRef: (FSRef *)fileRef;
- (NSString *) systemPathStringForFileRef: (FSRef *)fileRef;

@end // @interface TreeBuilder (PrivateMethods)


/* Helper class that is used to temporarily store additional info for child 
 * directories. It stores the info that is not maintained by the DirectoryItem 
 * class yet is needed while the child directory contents have not yet been
 * scanned.
 */
@interface TmpDirInfo : NSObject {
  DirectoryItem  *dirItem;
  UTCDateTime  creationDate;
@public
  FSRef  ref;
}

- (id) initWithDirectoryItem: (DirectoryItem *)dirItem
         fileRef: (FSRef *)ref creationDate: (UTCDateTime) creationDate;

- (DirectoryItem *) directoryItem;

- (NSComparisonResult) compareByCreationDate: (TmpDirInfo *)other;

@end // @interface TmpDirInfo


@implementation TmpDirInfo

// Overrides super's designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithDirectoryItem:fileRef:creationDate: instead.");
}

- (id) initWithDirectoryItem: (DirectoryItem *)dirItemVal
         fileRef: (FSRef *)refVal 
         creationDate: (UTCDateTime) creationDateVal {
  if (self = [super init]) {
    dirItem = [dirItemVal retain];
    ref = *refVal;
    creationDate = creationDateVal;
  }

  return self;
}

- (void) dealloc {
  [super dealloc];
  
  [dirItem release];
}

- (DirectoryItem *) directoryItem {
  return dirItem;
}

/* Note: The ordering is from most recent to the oldest. This is done so that
 * iteration starts with the oldest item when starting from the back of the
 * array.
 */
- (NSComparisonResult) compareByCreationDate: (TmpDirInfo *)other {
  if (creationDate.highSeconds == other->creationDate.highSeconds) {
    if (creationDate.lowSeconds == other->creationDate.lowSeconds) {
      if (creationDate.fraction == other->creationDate.fraction) {
        return NSOrderedSame;
      }
      else {
        return ( (creationDate.fraction < other->creationDate.fraction) 
                 ? NSOrderedDescending : NSOrderedAscending );
      }
    }
    else {
      return ( (creationDate.lowSeconds < other->creationDate.lowSeconds) 
               ? NSOrderedDescending : NSOrderedAscending );
    }
  }
  else {
    return ( (creationDate.highSeconds < other->creationDate.highSeconds) 
             ? NSOrderedDescending : NSOrderedAscending );
  }
}

@end // @implementation TmpDirInfo


@implementation TreeBuilder

+ (NSArray *) fileSizeMeasureNames {
  static NSArray  *fileSizeMeasureNames = nil;

  if (fileSizeMeasureNames == nil) {
    fileSizeMeasureNames = 
      [[NSArray arrayWithObjects: LogicalFileSize, PhysicalFileSize, nil] 
          retain];
  }
  
  return fileSizeMeasureNames;
}


- (id) init {
  return [self initWithFilteredTreeGuide: nil];
}


- (id) initWithFilteredTreeGuide: (FilteredTreeGuide *)treeGuideVal {
  if (self = [super init]) {
    treeGuide = [treeGuideVal retain];
    treeBalancer = [[TreeBalancer alloc] init];
    typeInventory = [[UniformTypeInventory defaultUniformTypeInventory] retain];
    
    hardLinkedFileNumbers = [[NSMutableSet alloc] initWithCapacity: 32];
    abort = NO;
    
    progressTracker = [[ProgressTracker alloc] init];
    
    pathBuffer = NULL;
    pathBufferLen = 0;
    
    // Note: allocating three separate arrays using the "BulkCatalogInfo"
    // struct. This ensures that there placed consecutively in memory, which
    // should help to speed up access to these arrays (it definitely should not
    // harm).
    bulkCatalogInfo = malloc(sizeof(BulkCatalogInfo));
    catalogInfoArray = ((BulkCatalogInfo *)bulkCatalogInfo)->catalogInfoArray;
    fileRefArray =     ((BulkCatalogInfo *)bulkCatalogInfo)->fileRefArray;
    namesArray =       ((BulkCatalogInfo *)bulkCatalogInfo)->namesArray;
    
    fileSizeMeasureFunction = NULL;
    [self setFileSizeMeasure: LogicalFileSize];
  }
  return self;
}


- (void) dealloc {
  [treeGuide release];
  [treeBalancer release];
  [typeInventory release];
  
  [hardLinkedFileNumbers release];
  [fileSizeMeasure release];
  
  [progressTracker release];
  
  free(pathBuffer);
  free(bulkCatalogInfo);
  
  [super dealloc];
}


- (NSString *) fileSizeMeasure {
  return fileSizeMeasure;
}

- (void) setFileSizeMeasure: (NSString *)measure {
  if ([measure isEqualToString: LogicalFileSize]) {
    fileSizeMeasureFunction = &getLogicalFileSize;
  }
  else if ([measure isEqualToString: PhysicalFileSize]) {
    fileSizeMeasureFunction = &getPhysicalFileSize;
  }
  else {
    NSAssert(NO, @"Invalid file size measure.");
  }
  
  if (measure != fileSizeMeasure) {
    [fileSizeMeasure release];
    fileSizeMeasure = [measure retain];
  }
}


- (void) abort {
  abort = YES;
}


- (TreeContext *)buildTreeForPath: (NSString *)path {
  FSRef  pathRef;
  Boolean  isDir;

  OSStatus  status = 
    FSPathMakeRef( (const UInt8 *) [path fileSystemRepresentation], 
	               &pathRef, &isDir );
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
  NSString  *volumePath = path;

  while (YES) {
    NSString  *parentPath = [volumePath stringByDeletingLastPathComponent];
    if ([parentPath isEqualToString: volumePath]) {
      // String cannot be reduced further, so must be start of volume.
      break;
    }
    fsattrs = [manager fileSystemAttributesAtPath: parentPath];

    unsigned long long  parentFileSystemNumber =
      [[fsattrs objectForKey: NSFileSystemNumber] unsignedLongLongValue];
    if (parentFileSystemNumber != fileSystemNumber) {
      // There was a change of filesystem, so the start of the volume has been
      // found.
      break;
    }
    volumePath = parentPath;
  }
  
  NSString  *relativePath =
    ([volumePath length] < [path length] ? 
       [path substringFromIndex: [volumePath length]] : @"");
  if ([relativePath isAbsolutePath]) {
    // Strip leading slash.
    relativePath = [relativePath substringFromIndex: 1];
  }     
       
  if ([relativePath length] > 0) {
    NSLog(@"Scanning volume %@ [%@], starting at %@", volumePath, 
             [manager displayNameAtPath: volumePath], relativePath);
  }
  else {
    NSLog(@"Scanning entire volume %@ [%@].", volumePath, 
             [manager displayNameAtPath: volumePath]);
  }
       
  TreeContext  *scanResult =
    [[[TreeContext alloc] initWithVolumePath: volumePath
                            fileSizeMeasure: fileSizeMeasure
                            volumeSize: volumeSize 
                            freeSpace: freeSpace
                            filter: [treeGuide fileItemTest]] autorelease];
  DirectoryItem  *scanTree = 
    [[[DirectoryItem allocWithZone: [Item dedicatedZone]] 
         initWithName: relativePath 
         parent: [scanResult scanTreeParent]
         flags: [self flagsForFileRef: &pathRef]] autorelease];

  [progressTracker startingTask];
        
  BOOL  ok = [self buildTreeForDirectory: scanTree fileRef: &pathRef
                     parentPath: volumePath];

  [progressTracker finishedTask];

  if (! ok) {
    return nil;
  }
  
  [scanResult setScanTree: scanTree];
  
  UniformTypeInventory  *typeInventory = 
    [UniformTypeInventory defaultUniformTypeInventory];
  // [typeInventory dumpTypesToLog];
    
  return scanResult;
}


- (NSDictionary *) progressInfo {
  return [progressTracker progressInfo];
}

@end // @implementation TreeBuilder


@implementation TreeBuilder (PrivateMethods)

- (BOOL) buildTreeForDirectory: (DirectoryItem *)dirItem 
           fileRef: (FSRef *)parentFileRef parentPath: (NSString *)parentPath {
  NSString  *path = [parentPath stringByAppendingPathComponent: [dirItem name]];

  FSIterator  iterator;
  { 
    OSStatus  result = FSOpenIterator(parentFileRef, kFSIterateFlat, &iterator);
    if (result != noErr) {
      NSLog( @"Couldn't create FSIterator for '%@': Error %i", path, result);
    
      return NO;
    }
  }
  
  [treeGuide descendIntoDirectory: dirItem];
  [progressTracker processingFolder: dirItem];

  NSMutableArray  *files = 
    [[NSMutableArray alloc] initWithCapacity: INITIAL_FILES_CAPACITY];
  NSMutableArray  *dirs = 
    [[NSMutableArray alloc] initWithCapacity: INITIAL_DIRS_CAPACITY];

  NSAutoreleasePool  *localAutoreleasePool = nil;
  
  int  i;
  
  while (YES) {
    // Declared here, to not needlessly put them on the recursive stack.
    ItemCount  actualCount = 0;
    OSStatus  result = FSGetCatalogInfoBulk( iterator,
                                             BULK_CATALOG_REQUEST_SIZE, 
                                             &actualCount, NULL,
                                             CATALOG_INFO_BITMAP,
                                             catalogInfoArray,
                                             fileRefArray, NULL,
                                             namesArray );
                                   
    if (result != noErr && result != errFSNoMoreItems) {
      if (result == afpAccessDenied) {
        NSAssert([dirs count] == 0 && [files count] == 0, 
                 @"Partial access denied?");
        [progressTracker skippedFolder: dirItem];
        // Note: In the progressInfo for TreeBuilder the skipped folders are
        // also counted as processed. In a way this is the case, so no need to
        // change this, at least not for now.
      }
      else {
        NSLog(@"Failed to get bulk catalog info for '%@': %i", path, result);
      }
      break;
    }
    
    if ( localAutoreleasePool == nil && actualCount > 16) {
      localAutoreleasePool = [[NSAutoreleasePool alloc] init];
    }
      
    for (i = 0; i < actualCount; i++) {
      FSCatalogInfo  *catalogInfo = &catalogInfoArray[i];
      FSRef  *childRef = &fileRefArray[i];
      HFSUniStr255  *name = &namesArray[i];

      NSString  *childName = 
        [[NSString alloc] initWithCharacters: (unichar *) &(name->unicode)
                            length: name->length];
                            
      // The "system path" path to the child item. It may not be needed, so it
      // is created lazily.
      NSString  *systemPath = nil; 

      if ([self includeItemForFileRef: childRef catalogInfo: catalogInfo 
                  systemPath: &systemPath]) {
        // Include this item
        
        UInt8  flags = 0;
        
        if (catalogInfo->nodeFlags & kFSNodeHardLinkMask) {
          flags |= FILE_IS_HARDLINKED;
        }
      
        if (catalogInfo->nodeFlags & kFSNodeIsDirectoryMask) {
          // A directory node.
          
          // Check if it is a package.
          if (systemPath == nil) {
            // Lazily create the system path to the child item
            systemPath = [self systemPathStringForFileRef: childRef];
          }
          if (systemPath != CouldNotEstablishSystemPath) {
            if ([[NSWorkspace sharedWorkspace] 
                    isFilePackageAtPath: systemPath]) {
              flags |= FILE_IS_PACKAGE;
            }
          }
          else {
            NSLog(@"Assuming directory w/o a system path is not a package.");
          }

          DirectoryItem  *dirChildItem = 
            [[DirectoryItem allocWithZone: [dirItem zone]] 
                initWithName: childName parent: dirItem flags: flags];

          // Only add directories that should be scanned (this does not
          // necessarily mean that it has passed the filter test already) 
          if ( [treeGuide shouldDescendIntoDirectory: dirChildItem] ) {
            TmpDirInfo  *tmpDirInfo = 
              [[TmpDirInfo alloc] initWithDirectoryItem: dirChildItem
                                    fileRef: childRef 
                                    creationDate: catalogInfo->createDate];

            [dirs addObject: tmpDirInfo];
            [tmpDirInfo release];
          }
          
          [dirChildItem release];
        }
        else {
          // A file node.
            
          ITEM_SIZE  childSize = fileSizeMeasureFunction(catalogInfo);
            
          UniformType  *fileType = 
            [typeInventory uniformTypeForExtension: [childName pathExtension]];
      
          PlainFileItem  *fileChildItem =
            [[PlainFileItem allocWithZone: [dirItem zone]] 
                initWithName: childName parent: dirItem size: childSize 
                  type: fileType flags: flags];

          // Only add file items that pass the filter test.
          if ( [treeGuide includeFileItem: fileChildItem] ) {
            [files addObject: fileChildItem];
          }
          
          [fileChildItem release];
        }
      }
      
      if (systemPath == CouldNotEstablishSystemPath) {
        NSLog(@"Failed to establish system path for %@/%@.", 
                  [dirItem path], childName);
      }
      
      [childName release];
    }
    
    if (result == errFSNoMoreItems) {
      break;
    }
  }
  
  // Sort the child directories by creation date, so that the oldest 
  // directories are scanned first. This affects the folder in which a 
  // hard-linked item will appear. This scanning order is particularly useful 
  // when a whole TimeMachine backup collection is scanned, as a file will be
  // shown in the earliest backup where it appeared. More generally though, the 
  // benefit is that the scanning order becomes deterministic.
  [dirs sortUsingSelector: @selector(compareByCreationDate:)];

  for (i = [dirs count]; --i >= 0; ) {
    TmpDirInfo  *tmpDirInfo = [dirs objectAtIndex: i];
    DirectoryItem  *dirChildItem = [tmpDirInfo directoryItem];

    if (!abort) {
      [self buildTreeForDirectory: dirChildItem
              fileRef: &( tmpDirInfo->ref )
              parentPath: path];
    }

    if ( [treeGuide includeFileItem: dirChildItem] ) {
      // The directory passed the test. So include it.
      
      // Temporarily boost retain count to ensure that the implicit release of
      // the tmpDirInfo object does not trigger deallocation of dirChildItem.
      [dirChildItem retain]; 
      
      // Replace the tmpDirInfo object with the actual DirectoryItem object.
      [dirs replaceObjectAtIndex: i withObject: dirChildItem];

      [dirChildItem release];
    }
    else {
      // The directory did not pass the test, so exclude it.
      [dirs removeObjectAtIndex: i];
    }
  }
  
  [dirItem setDirectoryContents: 
    [CompoundItem 
       compoundItemWithFirst: [treeBalancer createTreeForItems: files] 
                      second: [treeBalancer createTreeForItems: dirs]]];

  [files release];
  [dirs release];

  [localAutoreleasePool release];
  
  [treeGuide emergedFromDirectory: dirItem];
  [progressTracker processedFolder: dirItem];
  
  FSCloseIterator(iterator);
  
  return !abort;
}


/* Returns YES if the item should be included in the tree.
 *
 * The system path may optionally be provided (if already known). Also, 
 * a side effect of this method may be that the system path is set. This, 
 * however, is optional. It may still be nil.
 */
- (BOOL) includeItemForFileRef: (FSRef *)fileRef
           catalogInfo: (FSCatalogInfo *)catalogInfo
           systemPath: (NSString **)systemPath {
           
  if (catalogInfo->nodeFlags & kFSNodeHardLinkMask) {
    // The item is hard-linked (i.e. it appears more than once on this volume).
    
    if (*systemPath == nil) {
      // Lazily create the system path
      *systemPath = [self systemPathStringForFileRef: fileRef];      
    }
    if (*systemPath == CouldNotEstablishSystemPath) {
      NSLog(@"Excluding hard-linked file item w/o a system path.");
      return NO;
    }
    
    NSFileManager  *fileManager = [NSFileManager defaultManager];
    NSDictionary  *fileAttributes = 
      [fileManager fileAttributesAtPath: *systemPath traverseLink: NO];
    NSNumber  *fileNumber = 
      [fileAttributes objectForKey: NSFileSystemFileNumber];

    if (fileNumber == nil) {
      // Workaround for bug #2243134
      NSLog(@"Failed to get file number for the hard-linked file: %@\n Cannot establish if the file nas been included already, but including it anyway (possibly overestimating the amount of used disk space).", 
              *systemPath);
      return YES; 
    }
            
    if ([hardLinkedFileNumbers containsObject: fileNumber]) {
      // The item has already been encountered. So ignore it this
      // time so that it is not counted more than once.

      return NO;
    }
    else {
      [hardLinkedFileNumbers addObject: fileNumber];
    }
  }

  return YES;
}


/* Gets the flags (as used by FileItem) for the given file.
 */
- (UInt8) flagsForFileRef: (FSRef *)fileRef {
  UInt8  flags = 0;
  
  // It's physical per definition (otherwise it would not have an FSRef).

  // Is it hard-linked?  
  FSCatalogInfo  *catalogInfo = catalogInfoArray; // Use first entry in array
  OSStatus  result = FSGetCatalogInfo( fileRef, kFSCatInfoNodeFlags, 
                                       catalogInfo, NULL, NULL, NULL );
  if (catalogInfo->nodeFlags & kFSNodeHardLinkMask) {
    flags |= FILE_IS_HARDLINKED;
  }
  
  // Is it a package?
  NSString  *systemPath = [self systemPathStringForFileRef: fileRef];
  if (systemPath != CouldNotEstablishSystemPath) {
    if ([[NSWorkspace sharedWorkspace] isFilePackageAtPath: systemPath]) {
      flags |= FILE_IS_PACKAGE;
    }
  }
  
  return flags;
}


/* Gets the "system path" to the file associated with the given FSRef.
 *
 * The system path differs from the "display path" created by recursively using
 * -stringByAppendingPathComponent. In the latter, for example, slashes can
 * be used in individual path components (e.g. files can be named 
 * mydata-05/05/2008.doc), which is also how the files are shown in Finder.
 * In system paths, however, slashes are converted to colons, which is needed 
 * to actually get to the files given the path. The method
 * -fileAttributesAtPath:traverseLink: requires a system path for example.
 */
- (NSString *) systemPathStringForFileRef: (FSRef *)fileRef {
  if (pathBuffer == NULL) {
    // Allocate initial buffer

    pathBufferLen = 128; // Initial size
    pathBuffer = malloc(sizeof(UInt8) * pathBufferLen);
    NSAssert(pathBuffer != NULL, @"Malloc failed.");
  }
  
  while (YES) {
    OSStatus  status = FSRefMakePath(fileRef, pathBuffer, pathBufferLen);
    
    if (status == 0) {
      // All okay.
      return [NSString stringWithUTF8String: (const char*)pathBuffer];
    }
    else if (status == -2110) {
      // Buffer too short. Replace buffer by larger one.
      free(pathBuffer);
      
      pathBufferLen *= 2;
      pathBuffer = malloc(sizeof(UInt8) * pathBufferLen);
      NSAssert(pathBuffer != NULL, @"Malloc failed.");
    }
    else {
      // Failed to create path.
      NSLog(@"FSRefMakePath failed (code=%d)", status);
      return CouldNotEstablishSystemPath; 
    }
  }
}

@end // @implementation TreeBuilder (PrivateMethods)
