#import "FilteredTreeGuide.h"

#import "DirectoryItem.h"
#import "FileItemTest.h"
#import "FileItemPathStringCache.h"

@implementation FilteredTreeGuide

// Overrides designated initialiser
- (id) init {
  return [self initWithFileItemTest: nil packagesAsFiles: YES];
}

- (id) initWithFileItemTest: (NSObject <FileItemTest> *)itemTestVal
         packagesAsFiles: (BOOL) packagesAsFilesVal {
  if (self = [super init]) {
    itemTest = [itemTestVal retain];
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
    
    if ( [item isSpecial] ) {
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
  if ( packagesAsFiles ) {
    // Packages are treated as files. This means that the item should be 
    // constructed first before applying the test (as it may include an 
    // ItemSizeTest).
    return YES;
  }
  else {
    // Even though the directory item has not yet been fully created, the test
    // can be applied already. So only descend (and construct the contents) 
    // when it passed the test (and will be included in the tree).
    return ( [itemTest testFileItem: item
                         context: fileItemPathStringCache] != TEST_FAILED );
  }
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

@end
