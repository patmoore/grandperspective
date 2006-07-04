#import "TreeFilter.h"

#import "DirectoryItem.h"
#import "CompoundItem.h"
#import "TreeBalancer.h"
#import "FileItemTest.h"

@interface TreeFilter (PrivateMethods)

- (void) flattenAndFilterTree:(Item*)item
           directoryItems:(NSMutableArray*)dirItems
                fileItems:(NSMutableArray*)fileItems;

- (void) flattenAndFilterTree:(Item*)item;

@end // @interface TreeFilter (PrivateMethods)


@implementation TreeFilter

- (id) initWithFileItemTest:(NSObject <FileItemTest> *)itemTestVal {
  if (self = [super init]) {
    itemTest = [itemTestVal retain];
    
    treeBalancer = [[TreeBalancer alloc] init];

    tmpDirItems = nil;
    tmpFileItems = nil;
  }

  return self;
}


- (void) dealloc {
  [treeBalancer release];
  [itemTest release];
  
  [super dealloc];
}

- (DirectoryItem*) filterItemTree:(DirectoryItem*) dirItem {
  DirectoryItem  *newDirItem = 
    [[[DirectoryItem alloc] initWithName:[dirItem name] 
                              parent:[dirItem parentDirectory]] autorelease];

  NSMutableArray  *dirChildren = [[NSMutableArray alloc] initWithCapacity:64];
  NSMutableArray  *fileChildren = [[NSMutableArray alloc] initWithCapacity:512]; 

  [self flattenAndFilterTree:[dirItem getContents] 
          directoryItems: dirChildren fileItems: fileChildren];

  ITEM_SIZE  dirSize = 0; 
  int  i;
  
  // Add up the size of all file items that passed the test
  for (i = [fileChildren count]; --i >= 0; ) {
    FileItem  *oldFileItem = [fileChildren objectAtIndex:i];
    FileItem  *newFileItem = 
      [[FileItem alloc] initWithName:[oldFileItem name] parent:newDirItem
                          size:[oldFileItem itemSize]];
      
    [fileChildren replaceObjectAtIndex:i withObject:newFileItem];  
    dirSize += [newFileItem itemSize];
  }
  
  // Filter the contents of all directory items
  for (i = [dirChildren count]; --i >= 0; ) {
    DirectoryItem  *oldSubDirItem = [dirChildren objectAtIndex:i];
    DirectoryItem  *newSubDirItem = [self filterItemTree:oldSubDirItem];
    
    [dirChildren replaceObjectAtIndex:i withObject:newSubDirItem];
    dirSize += [newSubDirItem itemSize];
  }
  
  Item  *fileTree = [treeBalancer createTreeForItems: fileChildren];
  Item  *dirTree = [treeBalancer createTreeForItems: dirChildren];
  Item  *contentTree = [CompoundItem compoundItemWithFirst: fileTree 
                                       second: dirTree];
                                       
  [dirChildren release];
  [fileChildren release];
  
  [newDirItem setDirectoryContents:contentTree size:dirSize];

  return newDirItem;
}


@end


@implementation TreeFilter (PrivateMethods)

- (void) flattenAndFilterTree:(Item*)item
           directoryItems:(NSMutableArray*)dirItems
                fileItems:(NSMutableArray*)fileItems {
  if (item == nil) {
    // All done.
    return;
  }

  NSAssert(tmpDirItems==nil && tmpFileItems==nil, 
             @"Helper arrays already in use?");
  
  tmpDirItems = dirItems;
  tmpFileItems = fileItems;
  
  [self flattenAndFilterTree:item];
  
  tmpDirItems = nil;
  tmpFileItems = nil;
}

- (void) flattenAndFilterTree:(Item*)item  {
  if ([item isVirtual]) {
    [self flattenAndFilterTree:[((CompoundItem*)item) getFirst]];
    [self flattenAndFilterTree:[((CompoundItem*)item) getSecond]];
  }
  else if ([((FileItem*)item) isPlainFile]) {
    if ([itemTest testFileItem: ((FileItem*)item)] ) {
      // File item passed the test, so include it 
      [tmpFileItems addObject: item];
    }
  }
  else {
    [tmpDirItems addObject: item];
  }
}

@end