#import "TreeBuilder.h"

#import "CompoundItem.h"
#import "DirectoryItem.h" // Also imports FileItem.h
#import "TreeBalancer.h"


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
    fileSizeMeasure = LOGICAL_FILE_SIZE;
  }
  return self;
}


- (void) dealloc {
  [treeBalancer release];
  
  [super dealloc];
}


- (int) fileSizeMeasure {
  return fileSizeMeasure;
}

- (void) setFileSizeMeasure: (int)measure {
  NSAssert(measure==LOGICAL_FILE_SIZE || measure==PHYSICAL_FILE_SIZE, 
           @"Invalid file size measure.");
           
  fileSizeMeasure = measure;
}


- (void) abort {
  abort = YES;
}


- (DirectoryItem*) buildTreeForPath:(NSString*)path {
  FSRef  rootRef;
  Boolean  isDir;

  OSStatus  status = 
    FSPathMakeRef( [path fileSystemRepresentation], &rootRef, &isDir );
  
  NSAssert(isDir, @"Root is not a directory.");
  
  DirectoryItem*  rootItem = 
    [[[DirectoryItem alloc] initWithName:path parent:nil] autorelease];

  BOOL  ok = [self buildTreeForDirectory:rootItem parentPath:@"" ref:&rootRef];

  return ok ? rootItem : nil;
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
  ITEM_SIZE  dirSize = 0;
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
              (fileSizeMeasure == LOGICAL_FILE_SIZE ? 
                (bulkCatalogInfo.catalogInfoArray[i].dataLogicalSize +
                 bulkCatalogInfo.catalogInfoArray[i].rsrcLogicalSize) :
                (bulkCatalogInfo.catalogInfoArray[i].dataPhysicalSize +
                 bulkCatalogInfo.catalogInfoArray[i].rsrcPhysicalSize));
      
            FileItem  *fileChildItem =
              [[FileItem alloc] initWithName:childName parent:dirItem 
                                  size:childSize];

            [fileChildren addObject:fileChildItem];
            [fileChildItem release];

            dirSize += childSize;
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
    
    dirSize += [dirChildItem itemSize];
  }
  
  Item  *fileTree = [treeBalancer createTreeForItems:fileChildren];
  Item  *dirTree = [treeBalancer createTreeForItems:dirChildren];
  Item  *contentTree = [CompoundItem compoundItemWithFirst: fileTree 
                                       second: dirTree];

  [dirItem setDirectoryContents:contentTree size:dirSize];
  
  [fileChildren release];
  [dirChildren release];
  [dirFsRefs release];

  [localAutoreleasePool release];
  
  return !abort;
}

@end // @implementation TreeBuilder (PrivateMethods)
