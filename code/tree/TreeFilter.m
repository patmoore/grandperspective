#import "TreeFilter.h"

#import "PlainFileItem.h"
#import "DirectoryItem.h"
#import "CompoundItem.h"
#import "TreeContext.h"
#import "TreeBalancer.h"
#import "FileItemTest.h"
#import "FileItemPathStringCache.h"

@interface TreeFilter (PrivateMethods)

- (void) filterItemTree: (DirectoryItem *)oldDirItem 
           into: (DirectoryItem *)newDirItem;

- (void) flattenAndFilterSiblings: (Item *)item
           directoryItems: (NSMutableArray *)dirItems
                fileItems: (NSMutableArray *)fileItems;

- (void) flattenAndFilterSiblings: (Item *)item;

@end // @interface TreeFilter (PrivateMethods)


@implementation TreeFilter

- (id) initWithFileItemTest: (NSObject <FileItemTest> *)itemTestVal
         packagesAsFiles: (BOOL) packagesAsFilesVal {
  if (self = [super init]) {
    itemTest = [itemTestVal retain];
    packagesAsFiles = packagesAsFilesVal;
    
    treeBalancer = [[TreeBalancer alloc] init];
    
    fileItemPathStringCache = [[FileItemPathStringCache alloc] init];
    [fileItemPathStringCache setAddTrailingSlashToDirectoryPaths: YES];

    filterDisabledCount = 0;
    abort = NO;

    tmpDirItems = nil;
    tmpFileItems = nil;
  }

  return self;
}

- (void) dealloc {
  [itemTest release];
  [treeBalancer release];
  [fileItemPathStringCache release];
  
  [super dealloc];
}

- (TreeContext *)filterTree: (TreeContext *)oldTree {
  TreeContext  *filterResult = [oldTree contextAfterFiltering: itemTest];
  
  [self filterItemTree: [oldTree scanTree] into: [filterResult scanTree]];
          
  [filterResult postInit];
                 
  return filterResult; 
}

- (void) abort {
  abort = YES;
}

@end


@implementation TreeFilter (PrivateMethods)

- (void) filterItemTree: (DirectoryItem *)oldDir 
           into: (DirectoryItem *)newDir {
  NSMutableArray  *dirs = [[NSMutableArray alloc] initWithCapacity: 64];
  NSMutableArray  *files = [[NSMutableArray alloc] initWithCapacity: 512]; 
  
  if (packagesAsFiles && [newDir isPackage]) {
    filterDisabledCount++;
  }

  [self flattenAndFilterSiblings: [oldDir getContents] 
          directoryItems: dirs fileItems: files];

  if (!abort) { // Break recursion when task has been aborted.
    int  i;
  
    // Collect all file items that passed the test
    for (i = [files count]; --i >= 0; ) {
      PlainFileItem  *oldFile = [files objectAtIndex: i];
      PlainFileItem  *newFile = 
        (PlainFileItem *)[oldFile duplicateFileItem: newDir];
      
      [files replaceObjectAtIndex: i withObject: newFile];
    }
  
    // Filter the contents of all directory items
    for (i = [dirs count]; --i >= 0; ) {
      DirectoryItem  *oldSubDir = [dirs objectAtIndex: i];
      DirectoryItem  *newSubDir = 
        (DirectoryItem *)[oldSubDir duplicateFileItem: newDir];
      
      [self filterItemTree: oldSubDir into: newSubDir];
    
      if (! abort) {
        // Check to prevent inserting corrupt tree when filtering was aborted.
        
        [dirs replaceObjectAtIndex: i withObject: newSubDir];
      }
    }
  
    [newDir setDirectoryContents: 
      [CompoundItem 
         compoundItemWithFirst: [treeBalancer createTreeForItems: files] 
                        second: [treeBalancer createTreeForItems: dirs]]];
  }
  
  if (packagesAsFiles && [newDir isPackage]) {
    NSAssert( filterDisabledCount > 0, @"Count should be positive." );
    filterDisabledCount--;
  }

  [dirs release];
  [files release];
}


- (void) flattenAndFilterSiblings: (Item *)item
           directoryItems:(NSMutableArray *)dirItems
                fileItems:(NSMutableArray *)fileItems {
  if (item == nil) {
    // All done.
    return;
  }

  NSAssert(tmpDirItems==nil && tmpFileItems==nil, 
             @"Helper arrays already in use?");
  
  tmpDirItems = dirItems;
  tmpFileItems = fileItems;
  
  [self flattenAndFilterSiblings: item];
  
  tmpDirItems = nil;
  tmpFileItems = nil;
}

- (void) flattenAndFilterSiblings: (Item *)item {
  if (abort) {
    return;
  }

  if ([item isVirtual]) {
    [self flattenAndFilterSiblings: [((CompoundItem*)item) getFirst]];
    [self flattenAndFilterSiblings: [((CompoundItem*)item) getSecond]];
  }
  else if ([((FileItem *)item) isDirectory]) {
    FileItem  *filterSubject =
                 ( packagesAsFiles 
                   ? [((DirectoryItem *)item) itemWhenHidingPackageContents]
                   : (FileItem *)item );
  
    if ( filterDisabledCount > 0 
         || [itemTest testFileItem: filterSubject
                        context: fileItemPathStringCache] != TEST_FAILED ) {
      // Directory item passed the test (or test did not apply), so include it
      [tmpDirItems addObject: item];
    }
  }
  else {
    // It's a plain file
    
    if ( [((FileItem *)item) isSpecial] ) {
      // Exclude all special items (inside  the volume tree, these all 
      // represent freed space).
      //
      // TO DO: Check if special items should still always be excluded.

      return; 
    }
    
    if ( filterDisabledCount > 0
         || [itemTest testFileItem: ((FileItem *)item)
                        context: fileItemPathStringCache] != TEST_FAILED ) {
      // File item passed the test (or test did not apply), so include it 
      [tmpFileItems addObject: item];
    }
  }
}

@end