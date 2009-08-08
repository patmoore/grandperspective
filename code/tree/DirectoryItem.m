#import "DirectoryItem.h"

#import "PlainFileItem.h"
#import "UniformTypeInventory.h"


@implementation DirectoryItem

- (void) dealloc {
  [contents release];

  [super dealloc];
}


- (FileItem *) duplicateFileItem: (DirectoryItem *)newParent {
  return [[[DirectoryItem allocWithZone: [newParent zone]] 
              initWithName: name parent: newParent flags: flags] autorelease];
}


- (void) setDirectoryContents:(Item *)contentsVal {
  NSAssert(contents == nil, @"Contents should only be set once.");
  
  contents = [contentsVal retain];
  if (contents != nil) {
    size = [contents itemSize];
  }
}


- (void) replaceDirectoryContents: (Item *)newItem {
  NSAssert([newItem itemSize] == [contents itemSize], @"Sizes must be equal.");
  
  if (contents != newItem) {
    [contents release];
    contents = [newItem retain];
  }
}


- (FileItem *) itemWhenHidingPackageContents {
  if ([self isPackage]) {
    UniformType  *fileType = 
      [[UniformTypeInventory defaultUniformTypeInventory] 
         uniformTypeForExtension: [name pathExtension]];
  
    // Note: This item is short-lived, so it is allocated in the default zone.
    return [[[PlainFileItem alloc] initWithName: name
                                     parent: parent
                                     size: size
                                     type: fileType
                                     flags: flags] autorelease];
  }
  else {
    return self;
  }
}


- (NSString*) description {
  return [NSString stringWithFormat:@"DirectoryItem(%@, %qu, %@)", name, size,
                     [contents description]];
}


- (FILE_COUNT) numFiles {
  return [contents numFiles];
}

- (BOOL) isDirectory {
  return YES;
}

- (Item*) getContents {
  return contents;
}

@end
