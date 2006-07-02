#import "TreeBuilder.h"

#import "CompoundItem.h"
#import "DirectoryItem.h" // Also imports FileItem.h


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

// Note: The use of the auto-release mechanism is not used here for performance 
// reasons. In other words, this method assumes that the head of the list is
// retained by the callee. It will make sure that the new head of the list is 
// similarly retained, and release the previous head. 
- (Item*) extendCompoundItemList:(Item*) list withItem:(Item*) item;
  
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
    abort = NO;
  }
  return self;
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

  BOOL  ok = [self buildTreeForDirectory:rootItem parentPath:@"" ref:&rootRef];

  return ok ? rootItem : nil;
}

@end // @implementation TreeBuilder


@implementation TreeBuilder (PrivateMethods)

// Note: Not using auto-release for performance reasons. See interface
// definition for details.
- (Item*) extendCompoundItemList:(Item*) list withItem:(Item*) item {
  NSAssert(item!=nil, @"item not nil.");
  if (list != nil) {
    // Extend the existing list.
    Item  *newList = [[CompoundItem alloc] initWithFirst:item second:list];
    [list release];
    
    return newList;
  }
  else {
    // Start the list.
    [item retain];
    
    return item;
  }
}


- (BOOL) buildTreeForDirectory:(DirectoryItem*)dirItem 
           parentPath:(NSString*)parentPath ref:(FSRef*)ref {

  Item  *fileChildren = nil;
  //Item  *dirChildren = nil;

  NSAutoreleasePool  *localAutoreleasePool = nil;
  NSMutableArray  *dirChildrenArray = [NSMutableArray arrayWithCapacity:64];
  NSMutableArray  *dirFsRefs = [NSMutableArray arrayWithCapacity:64];
  
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

            //dirChildren = [self extendCompoundItemList: dirChildren
            //                      withItem: dirChildItem];
            [dirChildrenArray addObject:dirChildItem];
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

            fileChildren = [self extendCompoundItemList: fileChildren
                                   withItem: fileChildItem];
            [fileChildItem release];

            dirSize += childSize;
          }
          
          [childName release];
        }
      }
    }
    FSCloseIterator(iterator);
  }

  Item  *dirChildren = nil;
  for (i = [dirFsRefs count]; --i >= 0 && !abort; ) {
    DirectoryItem  *dirChildItem = [dirChildrenArray objectAtIndex:i];
    FSRefObject  *refObject = [dirFsRefs objectAtIndex:i];
    
    //NSString  *pathString =  [dirChildItem stringForFileItemPath];
    //NSLog(@"%@", pathString);

    [self buildTreeForDirectory:dirChildItem parentPath:path
            ref: &(refObject->ref)];
    
    dirSize += [dirChildItem itemSize];
    
    dirChildren = [self extendCompoundItemList: dirChildren
                          withItem: dirChildItem];
  }
  
  Item  *contentTree = [CompoundItem compoundItemWithFirst: fileChildren 
                                       second: dirChildren];

  //NSLog(@"Setting contents of %@", dirItem);
  //NSLog(@"Path = %@", [dirItem stringForFileItemPath]);
  [dirItem setDirectoryContents:contentTree size:dirSize];
  //NSString  *s = [dirItem description];
  //NSLog(@"Done setting contents.");
  
  [fileChildren release];
  [dirChildren release];

  [localAutoreleasePool release];
  
  return !abort;
}

@end // @implementation TreeBuilder (PrivateMethods)
