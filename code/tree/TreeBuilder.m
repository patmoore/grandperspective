#import "TreeBuilder.h"

#import "CompoundItem.h"
#import "DirectoryItem.h" // Also imports FileItem.h
#import "TreeBalancer.h"
#import "TreeContext.h"


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


- (TreeContext *)buildTreeForPath: (NSString *)path {
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
    
  if (! [self buildTreeForDirectory: [scanResult scanTree] 
                parentPath: volumePath ref: &pathRef]) {
    return nil;
  }
  
  [scanResult postInit];
  
  return scanResult;
}

@end // @implementation TreeBuilder


@implementation TreeBuilder (PrivateMethods)

- (BOOL) buildTreeForDirectory:(DirectoryItem*)dirItem 
           parentPath:(NSString*)parentPath ref:(FSRef*)ref {

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
