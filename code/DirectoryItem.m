#import "DirectoryItem.h"


@implementation DirectoryItem

- (void) dealloc {
  [contents release];
  [fileItemPathStringCache release];

  [super dealloc];
}


- (void) setDirectoryContents:(Item*)contentsVal size:(ITEM_SIZE)dirSize {
  NSAssert(contents == nil, @"Contents should only be set once.");
  
  contents = [contentsVal retain];
  size = dirSize;
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

- (NSString*) stringForFileItemPath {
  if (fileItemPathStringCache == nil) {
    fileItemPathStringCache = [[super stringForFileItemPath] retain];
  }

  return fileItemPathStringCache;
}

- (void) clearFileItemPathStringCache {
  [fileItemPathStringCache release];
  fileItemPathStringCache = nil;
}

@end
