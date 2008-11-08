#import "FilteredTreeGuide.h"

#import "DirectoryItem.h"
#import "FileItemTest.h"
#import "FileItemPathStringCache.h"
#import "ItemSizeTestFinder.h"


@implementation FilteredTreeGuide

// Overrides designated initialiser
- (id) init {
  return [self initWithFileItemTest: nil packagesAsFiles: YES];
}

- (id) initWithFileItemTest: (NSObject <FileItemTest> *)itemTestVal
         packagesAsFiles: (BOOL) packagesAsFilesVal {
  if (self = [super init]) {
    itemTest = nil;
    testUsesSize = NO;
    [self setFileItemTest: itemTestVal];

    packagesAsFiles = packagesAsFilesVal;
    
    packageCount = 0;
    
    fileItemPathStringCache = [[FileItemPathStringCache alloc] init];
    [fileItemPathStringCache setAddTrailingSlashToDirectoryPaths: YES];
  }

  return self;
}

- (void) dealloc {
  [itemTest release];
  [fileItemPathStringCache release];
  
  [super dealloc];
}


- (BOOL) packagesAsFiles {
  return packagesAsFiles;
}

- (void) setPackagesAsFiles: (BOOL) flag {
  packagesAsFiles = flag;
}


- (NSObject <FileItemTest>*) fileItemTest {
  return itemTest;
}

- (void) setFileItemTest: (NSObject <FileItemTest> *) test {
  if (itemTest != test) {
    [itemTest release];
    itemTest = [test retain];
    
    // Check if the test includes an ItemSizeTest
    if (itemTest != nil) {
      ItemSizeTestFinder  *sizeTestFinder = 
        [[[ItemSizeTestFinder alloc] init] autorelease];
      
      [test acceptFileItemTestVisitor: sizeTestFinder];
      testUsesSize = [sizeTestFinder itemSizeTestFound];
    }
    else {
      testUsesSize = NO;
    }
  }
}


- (FileItem *) includeFileItem: (FileItem *)item {
  FileItem  *proxyItem = item; // Default

  if ( [item isDirectory] ) {
    if ( packagesAsFiles ) {
      proxyItem = [((DirectoryItem *)item) itemWhenHidingPackageContents];
    }
  }
  else {
    // It's a plain file
    
    if ( ! [item isPhysical] ) {
      // Exclude all special items (inside  the volume tree, these all 
      // represent freed space).
      //
      // TO DO: Check if special items should still always be excluded.

      return nil; 
    }
  }

  if ( packagesAsFiles && packageCount > 0 ) {
    // Currently inside opaque package (implying that a tree is being 
    // constructed). Include all items.
    return proxyItem;
  }

  if ( itemTest == nil 
       || [itemTest testFileItem: proxyItem
                      context: fileItemPathStringCache] != TEST_FAILED ) {
    // The item passed the test.
    return proxyItem;
  }
  
  return nil;
}


- (BOOL) shouldDescendIntoDirectory: (DirectoryItem *)item {
  FileItem  *proxyItem = item; // Default
  
  if ( packagesAsFiles ) {
    if ( testUsesSize) {
      // The test considers the file's size. This means that the item should be
      // constructed first before applying the test.
      return YES;
    }
    else {
      // Even though the directory has not yet been constructed, the test can 
      // be applied to its plain file proxy.
      proxyItem = [((DirectoryItem *)item) itemWhenHidingPackageContents];
    }
  }

  // Even though the directory item has not yet been fully created, the test
  // can be applied already. So only descend (and construct the contents) 
  // when it passed the test (and will be included in the tree).
  return ( itemTest == nil 
           || [itemTest testFileItem: proxyItem
                          context: fileItemPathStringCache] != TEST_FAILED );
}


- (void) descendIntoDirectory: (DirectoryItem *)item {   
  if ( [item isPackage] ) {
    packageCount++;
  }
}

- (void) emergedFromDirectory: (DirectoryItem *)item {
  if ( [item isPackage] ) {
    NSAssert(packageCount > 0, @"Count should be positive." );
    packageCount--;
  }
}

@end // @implementation FilteredTreeGuide

