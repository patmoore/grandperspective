#import "DirectoryItem.h"


@implementation DirectoryItem

- (void) dealloc {
  [contents release];

  [super dealloc];
}


- (FileItem *) duplicateFileItem: (DirectoryItem *)newParent {
  return [[[DirectoryItem alloc] initWithName: name
                                   parent: newParent
                                   flags: flags] autorelease];
}


- (void) setDirectoryContents:(Item *)contentsVal {
  NSAssert(contents == nil, @"Contents should only be set once.");
  
  contents = [contentsVal retain];
  size = (contents == nil) ? 0 : [contents itemSize];
}


- (void) replaceDirectoryContents: (Item *)newItem {
  NSAssert([newItem itemSize] == [contents itemSize], @"Sizes must be equal.");
  
  if (contents != newItem) {
    [contents release];
    contents = [newItem retain];
  }
}


- (NSString*) description {
  return [NSString stringWithFormat:@"DirectoryItem(%@, %qu, %@)", name, size,
                     [contents description]];
}


- (BOOL) isPlainFile {
  return NO;
}

- (Item*) getContents {
  return contents;
}

@end
