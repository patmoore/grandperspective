#import "TreeBuilder.h"

#import "CompoundItem.h"
#import "DirectoryItem.h"
#import "PlainFileItem.h"
#import "TreeBalancer.h"
#import "TreeContext.h"
#import "UniformTypeInventory.h"


NSString  *LogicalFileSize = @"logical";
NSString  *PhysicalFileSize = @"physical";


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

typedef struct  {
  FSCatalogInfo  catalogInfoArray[BULK_CATALOG_REQUEST_SIZE];
  FSRef          fileRefArray[BULK_CATALOG_REQUEST_SIZE];
  HFSUniStr255   namesArray[BULK_CATALOG_REQUEST_SIZE];
} BulkCatalogInfo;


@interface TreeBuilder (PrivateMethods)

- (BOOL) buildTreeForDirectory: (DirectoryItem *)dirItem 
           fileRef: (FSRef *)fileRef parentPath: (NSString *)parentPath;
           
- (BOOL) includeItemForFileRef: (FSRef *)fileRef
           catalogInfo: (FSCatalogInfo *)catalogInfo;

- (NSString *) pathStringForFileRef: (FSRef *)fileRef;

@end // @interface TreeBuilder (PrivateMethods)


@interface FSRefObject : NSObject {
@public
  FSRef  ref;
}

- (id) initWithFileRef: (FSRef *)ref;

@end // @interface FSRefObject


@implementation FSRefObject

// Overrides super's designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithFileRef instead.");
}

- (id) initWithFileRef: (FSRef *)refVal {
  if (self = [super init]) {
    ref = *refVal;
  }

  return self;
}

@end // @implementation FSRefObject


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
  if (self = [super init]) {
    treeBalancer = [[TreeBalancer alloc] init];
    typeInventory = [[UniformTypeInventory defaultUniformTypeInventory] retain];
  
    hardLinkedFileNumbers = [[NSMutableSet alloc] initWithCapacity: 32];
    abort = NO;
    
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
    
    [self setFileSizeMeasure: LogicalFileSize];
  }
  return self;
}


- (void) dealloc {
  [treeBalancer release];
  [typeInventory release];
  
  [hardLinkedFileNumbers release];
  [fileSizeMeasure release];
  
  free(pathBuffer);
  free(bulkCatalogInfo);
  
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
                            scanPath: relativePath
                            fileSizeMeasure: fileSizeMeasure
                            volumeSize: volumeSize 
                            freeSpace: freeSpace] autorelease];
    
  if (! [self buildTreeForDirectory: [scanResult scanTree] fileRef: &pathRef
                parentPath: volumePath]) {
    return nil;
  }
  
  [scanResult postInit];
  
  UniformTypeInventory  *typeInventory = 
    [UniformTypeInventory defaultUniformTypeInventory];
  // [typeInventory dumpTypesToLog];
    
  return scanResult;
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
  
  NSMutableArray  *files = [[NSMutableArray alloc] initWithCapacity: 128];
  NSMutableArray  *dirs = [[NSMutableArray alloc] initWithCapacity: 32];
  NSMutableArray  *dirFileRefs = [[NSMutableArray alloc] initWithCapacity: 32];

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
      NSLog(@"Failed to get bulk catalog info for %@: %i", path, result);
      break;
    }
      
    if ( actualCount > 16 && localAutoreleasePool == nil) {
      localAutoreleasePool = [[NSAutoreleasePool alloc] init];
    }
      
    for (i = 0; i < actualCount; i++) {
      FSCatalogInfo  *catalogInfo = &catalogInfoArray[i];
      FSRef  *childRef = &fileRefArray[i];
      HFSUniStr255  *name = &namesArray[i];

      NSString  *childName = 
        [[NSString alloc] initWithCharacters: (unichar *) &(name->unicode)
                            length: name->length];

      if ([self includeItemForFileRef: childRef catalogInfo: catalogInfo]) {
        // Include this item
        
        UInt8  flags = 0;
        
        if (catalogInfo->nodeFlags & kFSNodeHardLinkMask != 0) {
          flags |= FILEITEM_HARDLINKED;
        }
      
        if (catalogInfo->nodeFlags & kFSNodeIsDirectoryMask) {
          // A directory node.

          DirectoryItem  *dirChildItem = 
            [[DirectoryItem alloc] initWithName: childName parent: dirItem
                                     flags: flags];
          [dirs addObject: dirChildItem];
          [dirChildItem release];

          FSRefObject  *refObject = 
            [[FSRefObject alloc] initWithFileRef: childRef];
          [dirFileRefs addObject: refObject];
          [refObject release];
        }
        else {
          // A file node.
            
          ITEM_SIZE  childSize = 
            (useLogicalFileSize ? 
              (catalogInfo->dataLogicalSize  + catalogInfo->rsrcLogicalSize) :
              (catalogInfo->dataPhysicalSize + catalogInfo->rsrcPhysicalSize));
            
          UniformType  *fileType = 
            [typeInventory uniformTypeForExtension: [childName pathExtension]];
      
          PlainFileItem  *fileChildItem =
            [[PlainFileItem alloc] initWithName: childName parent: dirItem 
                                     size: childSize type: fileType 
                                     flags: flags];
          [files addObject: fileChildItem];
          [fileChildItem release];
        }
      }
      
      [childName release];
    }
    
    if (result == errFSNoMoreItems) {
      break;
    }
  }

  for (i = [dirFileRefs count]; --i >= 0 && !abort; ) {
    [self buildTreeForDirectory: [dirs objectAtIndex: i]
            fileRef: &( ((FSRefObject *)[dirFileRefs objectAtIndex: i])->ref )
            parentPath: path];
  }
  
  [dirItem setDirectoryContents: 
    [CompoundItem 
       compoundItemWithFirst: [treeBalancer createTreeForItems: files] 
                      second: [treeBalancer createTreeForItems: dirs]]];
  
  [files release];
  [dirs release];
  [dirFileRefs release];

  [localAutoreleasePool release];
  
  FSCloseIterator(iterator);
    
  return !abort;
}


- (BOOL) includeItemForFileRef: (FSRef *)fileRef
           catalogInfo: (FSCatalogInfo *)catalogInfo {
           
  if (catalogInfo->nodeFlags & kFSNodeHardLinkMask) {
    // The item is hard-linked (i.e. it appears more than once on this volume).

    // Get the path to the item.
    //
    // Note: Constructing the path from the FSRef, as opposed to (recursively)
    // using -stringByAppendingPathComponent. The reason is that the former
    // converts slashes in individual path components (e.g. files named
    // mydata-05/05/2008.doc) to colons, which is needed for 
    // -fileAttributesAtPath:traverseLink: to work). For displaying path names,
    // the latter works fine, as this is also the way that names are shown in
    // Finder (and thus more familiar to users).
    NSString  *path = [self pathStringForFileRef: fileRef]; 
    
    NSFileManager  *fileManager = [NSFileManager defaultManager];
    NSDictionary  *fileAttributes = 
      [fileManager fileAttributesAtPath: path traverseLink: NO];
    NSNumber  *fileNumber = 
      [fileAttributes objectForKey: NSFileSystemFileNumber];
            
    if ([hardLinkedFileNumbers containsObject: fileNumber]) {
      // The item has already been encountered. So ignore it this
      // time so that it is not counted more than once.

      return NO;
    }
    else {
      [hardLinkedFileNumbers addObject: fileNumber];
    }
   
    return YES;
  }
}


- (NSString *) pathStringForFileRef: (FSRef *)fileRef {
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
      NSAssert1(NO, @"Unknown status code %d", status);
    }
  }
}


@end // @implementation TreeBuilder (PrivateMethods)
