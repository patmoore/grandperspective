#import "TreeFilter.h"

#import "DirectoryItem.h"
#import "CompoundItem.h"
#import "TreeBalancer.h"
#import "FileItemTest.h"
#import "FileItemPathStringCache.h"

@interface TreeFilter (PrivateMethods)

- (void) flattenAndFilterSiblings: (Item *)item
           directoryItems: (NSMutableArray *)dirItems
                fileItems: (NSMutableArray *)fileItems;

- (void) flattenAndFilterSiblings: (Item *)item;

@end // @interface TreeFilter (PrivateMethods)


@implementation TreeFilter

- (id) initWithFileItemTest:(NSObject <FileItemTest> *)itemTestVal {
  if (self = [super init]) {
    itemTest = [itemTestVal retain];
    
    treeBalancer = [[TreeBalancer alloc] init];
    
    fileItemPathStringCache = [[FileItemPathStringCache alloc] init];
    [fileItemPathStringCache setAddTrailingSlashToDirectoryPaths: YES];

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

- (DirectoryItem*) filterItemTree:(DirectoryItem*) dirItem {
  DirectoryItem  *newDirItem = 
    [[[DirectoryItem alloc] initWithName: [dirItem name] 
                              parent: [dirItem parentDirectory]] autorelease];

  NSMutableArray  *dirChildren = [[NSMutableArray alloc] initWithCapacity: 64];
  NSMutableArray  *fileChildren = [[NSMutableArray alloc] initWithCapacity:512]; 

  [self flattenAndFilterSiblings: [dirItem getContents] 
          directoryItems: dirChildren fileItems: fileChildren];

  if (!abort) { // Break recursion when task has been aborted.
    ITEM_SIZE  dirSize = 0; 
    int  i;
  
    // Add up the size of all file items that passed the test
    for (i = [fileChildren count]; --i >= 0; ) {
      FileItem  *oldFileItem = [fileChildren objectAtIndex: i];
      FileItem  *newFileItem = 
        [[FileItem alloc] initWithName: [oldFileItem name] parent: newDirItem
                            size: [oldFileItem itemSize]];
      
      [fileChildren replaceObjectAtIndex: i withObject: newFileItem];  
      dirSize += [newFileItem itemSize];
      
      [newFileItem release];
    }
  
    // Filter the contents of all directory items
    for (i = [dirChildren count]; --i >= 0; ) {
      DirectoryItem  *oldSubDirItem = [dirChildren objectAtIndex: i];
      DirectoryItem  *newSubDirItem = [self filterItemTree: oldSubDirItem];
    
      if (newSubDirItem != nil) {
        // Check to prevent inserting "nil" when filtering was aborted.
        
        [dirChildren replaceObjectAtIndex: i withObject: newSubDirItem];
        dirSize += [newSubDirItem itemSize];
      }
      else {
        // There's really no point in doing this, as the entire tree will
        // be discarded anyway. But hey, omitting this feels wrong. ;-)
        
        dirSize += [oldSubDirItem itemSize];
      }
    }
  
    Item  *fileTree = [treeBalancer createTreeForItems: fileChildren];
    Item  *dirTree = [treeBalancer createTreeForItems: dirChildren];
    Item  *contentTree = [CompoundItem compoundItemWithFirst: fileTree 
                                         second: dirTree];
                                       
    [newDirItem setDirectoryContents: contentTree size: dirSize];
  }

  [dirChildren release];
  [fileChildren release];
  
  // Must check "abort" flag again, as otherwise the returned tree could be 
  // corrupt.
  return (abort ? nil : newDirItem);
}


- (void) abort {
  abort = YES;
}

@end


@implementation TreeFilter (PrivateMethods)

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

- (void) flattenAndFilterSiblings: (Item *)item  {
  if (abort) {
    return;
  }

  if ([item isVirtual]) {
    [self flattenAndFilterSiblings: [((CompoundItem*)item) getFirst]];
    [self flattenAndFilterSiblings: [((CompoundItem*)item) getSecond]];
  }
  else if ([((FileItem*)item) isPlainFile]) {
    if ([itemTest testFileItem: ((FileItem*)item)
                    context: fileItemPathStringCache] ) {
      // File item passed the test, so include it 
      [tmpFileItems addObject: item];
    }
  }
  else {
    [tmpDirItems addObject: item];
  }
}

@end