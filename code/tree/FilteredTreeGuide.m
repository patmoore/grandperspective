#import "FilteredTreeGuide.h"

#import "DirectoryItem.h"
#import "FileItemTest.h"
#import "FileItemPathStringCache.h"

@implementation FilteredTreeGuide

- (id) initWithFileItemTest: (NSObject <FileItemTest> *)itemTestVal
         packagesAsFiles: (BOOL) packagesAsFilesVal {
  if (self = [super init]) {
    itemTest = [itemTestVal retain];
    packagesAsFiles = packagesAsFilesVal;
    
    filterDisabledCount = 0;
    
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

- (NSObject <FileItemTest>*) fileItemTest {
  return itemTest;
}


- (BOOL) shouldDescendIntoFileItem: (FileItem *)item {
  FileItem  *filterSubject = item; // Default

  if ( [item isDirectory] ) {
    if ( packagesAsFiles ) {
      filterSubject = [((DirectoryItem *)item) itemWhenHidingPackageContents];
    }
  }
  else {
    // It's a plain file
    
    if ( [item isSpecial] ) {
      // Exclude all special items (inside  the volume tree, these all 
      // represent freed space).
      //
      // TO DO: Check if special items should still always be excluded.

      return NO; 
    }
  }
    
  return ( filterDisabledCount > 0
           || [itemTest testFileItem: filterSubject
                          context: fileItemPathStringCache] != TEST_FAILED );
}


- (FileItem *) descendIntoFileItem: (FileItem *)item {   
  if ( [item isDirectory] ) {
    if (packagesAsFiles && [ ((DirectoryItem *)item) isPackage]) {
      filterDisabledCount++;
      
      return [((DirectoryItem *)item) itemWhenHidingPackageContents];
    }
  }
  
  return item;
}

- (void) emergedFromFileItem: (FileItem *)item {
  if ( [item isDirectory] ) {
    if (packagesAsFiles && [ ((DirectoryItem *)item) isPackage]) {
      NSAssert( filterDisabledCount > 0, @"Count should be positive." );
      filterDisabledCount--;
    }
  }
}

@end
