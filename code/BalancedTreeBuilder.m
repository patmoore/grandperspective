#import "BalancedTreeBuilder.h"

#import "CompoundItem.h"
#import "DirectoryItem.h" // Also imports FileItem.h
#import "PeekingEnumerator.h"


int compareBySize(id item1, id item2, void* context) {
  ITEM_SIZE  size1 = [item1 itemSize];
  ITEM_SIZE  size2 = [item2 itemSize];
  
  if (size1 < size2) {
    return NSOrderedAscending;
  }
  if (size1 > size2) {
    return NSOrderedDescending;
  }
  return NSOrderedSame;
}

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


@interface BalancedTreeBuilder (PrivateMethods)

- (Item*) createTreeForItems:(NSMutableArray*)items;
  
- (void) buildTreeForDirectory:(DirectoryItem*)dirItem 
           parentPath:(NSString*)parentPath ref:(FSRef*)ref;

@end // @interface BalancedTreeBuilder (PrivateMethods)


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


@implementation BalancedTreeBuilder

- (id) init {
  if (self = [super init]) {
    tmpArray = [[NSMutableArray alloc] initWithCapacity:1024];
    separateFilesAndDirs = YES;
    abort = NO;
  }
  return self;
}

- (void) dealloc {
  [tmpArray release];
}


- (void) setSeparatesFilesAndDirs:(BOOL)option {
  separateFilesAndDirs = option;
}

- (BOOL) separatesFilesAndDirs {
  return separateFilesAndDirs;
}


- (void) abort {
  abort = YES;
}


- (FileItem*) buildTreeForPath:(NSString*)path {
  FSRef  rootRef;
  Boolean  isDir;

  OSStatus  status = FSPathMakeRef( [path UTF8String], &rootRef, &isDir );
  
  NSAssert(isDir, @"Root is not a directory.");
  
  DirectoryItem*  rootItem = 
    [[[DirectoryItem alloc] initWithName:path parent:nil] autorelease];

  [self buildTreeForDirectory:rootItem parentPath:@"" ref:&rootRef];

  return rootItem;
}

@end // @implementation BalancedTreeBuilder


@implementation BalancedTreeBuilder (PrivateMethods)

// Note: assumes that array may be modified for sorting!
- (Item*) createTreeForItems:(NSMutableArray*)items {

  if ([items count]==0) {
    // No items, so nothing needs doing: return immediately.
    return nil;
  }
  
  [items sortUsingFunction:compareBySize context:nil];

  // Not using auto-release to minimise size of auto-release pool.
  PeekingEnumerator  *sortedItems = 
    [[PeekingEnumerator alloc] initWithEnumerator:[items objectEnumerator]];
  
  NSMutableArray*  sortedBranches = tmpArray;
  NSAssert(tmpArray!=nil && [tmpArray count]==0, @"Temporary array not valid."); 
  
  int  branchesGetIndex = 0;
  int  numBranches = 0;

  while (YES) {
    Item*  first = nil;
    Item*  second = nil;

    while (second == nil) {
      Item*  smallest;

      if ([sortedItems peekObject]==nil || // Out of leafs, or
          (branchesGetIndex < numBranches && // orphaned branches exist
           compareBySize([sortedBranches objectAtIndex:branchesGetIndex],
                         [sortedItems peekObject], nil) ==
           NSOrderedAscending)) {      // and the branch is smaller.
        if (branchesGetIndex < numBranches) {
          smallest = [sortedBranches objectAtIndex:branchesGetIndex++];
        }
        else {
          // We're finished building the tree
          
          NSAssert(first != nil, @"First is nil.");
          [first retain];
        
          // Clean up
          [sortedBranches removeAllObjects]; // Keep array for next time.
          [sortedItems release];
          
          return [first autorelease];
        }
      }
      else {
        smallest = [sortedItems nextObject];
      }
      NSAssert(smallest != nil, @"Smallest is nil.");
      
      if (first == nil) {
        first = smallest;
      }
      else {
        second = smallest;
      }
    }
    
    id  newBranch = 
      [[CompoundItem alloc] initWithFirst:first second:second];
    numBranches++;
    [sortedBranches addObject:newBranch];
    // Not auto-releasing to minimise size of auto-release pool.
    [newBranch release];
  }
}


- (void) buildTreeForDirectory:(DirectoryItem*)dirItem 
           parentPath:(NSString*)parentPath ref:(FSRef*)ref {
  // TEMP
  //if ([[dirItem name] isEqualToString:@"exclude-me"]) {
  //  return;
  //}    
           
  NSMutableArray  *fileChildren = 
    [[NSMutableArray alloc] initWithCapacity:256];
  NSMutableArray  *dirChildren = 
    [[NSMutableArray alloc] initWithCapacity:64];
  NSMutableArray  *dirFsRefs = 
    [[NSMutableArray alloc] initWithCapacity:64];

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

            if (!separateFilesAndDirs) {
              [fileChildren addObject:dirChildItem];
            }
            
            [dirFsRefs addObject:refObject];

            [dirChildItem release];
            [refObject release];
          }
          else {
            // A file node.
                      
            ITEM_SIZE  childSize = 
              (bulkCatalogInfo.catalogInfoArray[i].dataLogicalSize +
               bulkCatalogInfo.catalogInfoArray[i].rsrcLogicalSize);
      
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

  for (i = [dirChildren count]; --i >=0 && !abort; ) {
    FSRefObject  *refObject = [dirFsRefs objectAtIndex:i];
    DirectoryItem  *dirChildItem = [dirChildren objectAtIndex:i];
    
    [self buildTreeForDirectory:dirChildItem parentPath:path
            ref: &(refObject->ref)];
    
    dirSize += [dirChildItem itemSize];
  }                                                               

  Item*  contentTree;
  if (separateFilesAndDirs) {
    Item*  fileTree = [self createTreeForItems:fileChildren];
    Item*  dirTree = [self createTreeForItems:dirChildren];
    
    contentTree = [CompoundItem compoundItemWithFirst:fileTree second:dirTree];
  }
  else {
    // Note: In this case, "fileChildren" contains all children.
    contentTree = [self createTreeForItems:fileChildren];
  }

  [dirItem setDirectoryContents:contentTree size:dirSize];
  
  [fileChildren release];
  [dirChildren release];
  [dirFsRefs release];
  [localAutoreleasePool release];
}

@end // @implementation BalancedTreeBuilder (PrivateMethods)
