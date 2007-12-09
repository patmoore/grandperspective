#import "TreeFilter.h"

#import "DirectoryItem.h"
#import "CompoundItem.h"
#import "TreeHistory.h"
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

- (void) filterItemTree: (DirectoryItem *)oldDirItem 
           into: (DirectoryItem *)newDirItem {
  NSMutableArray  *dirChildren = [[NSMutableArray alloc] initWithCapacity: 64];
  NSMutableArray  *fileChildren = [[NSMutableArray alloc] initWithCapacity:512]; 

  [self flattenAndFilterSiblings: [oldDirItem getContents] 
          directoryItems: dirChildren fileItems: fileChildren];

  if (!abort) { // Break recursion when task has been aborted.
    int  i;
  
    // Collect all file items that passed the test
    for (i = [fileChildren count]; --i >= 0; ) {
      FileItem  *oldFileItem = [fileChildren objectAtIndex: i];
      FileItem  *newFileItem = 
        [[FileItem alloc] initWithName: [oldFileItem name] parent: newDirItem
                            size: [oldFileItem itemSize]];
      
      [fileChildren replaceObjectAtIndex: i withObject: newFileItem];  
      
      [newFileItem release];
    }
  
    // Filter the contents of all directory items
    for (i = [dirChildren count]; --i >= 0; ) {
      DirectoryItem  *oldSubDirItem = [dirChildren objectAtIndex: i];
      DirectoryItem  *newSubDirItem = 
        [[[DirectoryItem alloc] initWithName: [oldSubDirItem name]
                                  parent: newDirItem] autorelease];
      
      [self filterItemTree: oldSubDirItem into: newSubDirItem];
    
      if (! abort) {
        // Check to prevent inserting corrupt tree when filtering was aborted.
        
        [dirChildren replaceObjectAtIndex: i withObject: newSubDirItem];
      }
    }
  
    Item  *fileTree = [treeBalancer createTreeForItems: fileChildren];
    Item  *dirTree = [treeBalancer createTreeForItems: dirChildren];
    Item  *contentTree = [CompoundItem compoundItemWithFirst: fileTree 
                                         second: dirTree];
                                       
    [newDirItem setDirectoryContents: contentTree];
  }

  [dirChildren release];
  [fileChildren release];
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