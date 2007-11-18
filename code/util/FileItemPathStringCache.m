#import "FileItemPathStringCache.h"

#import "DirectoryItem.h"

@interface FileItemPathStringCache (PrivateMethods)

- (void) fillCacheToItem: (FileItem *) item;

@end


@implementation FileItemPathStringCache

- (id) init {
  if (self = [super init]) {
    addTrailingSlashToDirectoryPaths = NO;
    
    cachedPathStrings = [[NSMutableArray alloc] initWithCapacity: 8];
    lastFileItem = nil;
  }
  
  return self;
}

- (void) dealloc {
  [cachedPathStrings release];
  [lastFileItem release];
  
  [super dealloc];
}


- (BOOL) addTrailingSlashToDirectoryPaths {
  return addTrailingSlashToDirectoryPaths;
}

- (void) setAddTrailingSlashToDirectoryPaths: (BOOL)flag {
  addTrailingSlashToDirectoryPaths = flag;
}


- (NSString*) pathStringForFileItem: (FileItem *)item {
  DirectoryItem  *parentDirectory = [item parentDirectory];

  while (lastFileItem != item && 
         lastFileItem != parentDirectory &&
         lastFileItem != nil) {
    [cachedPathStrings removeLastObject];
    [lastFileItem release];
    lastFileItem = [[lastFileItem parentDirectory] retain];
  }

  if (lastFileItem == item) {
    // Found it
    return [cachedPathStrings lastObject];
  }

  NSString  *pathString;
  
  if (parentDirectory == nil) {
    pathString = [item name];
  }
  else {
    if (lastFileItem == nil) {
      // Exhausted the cache. Fill it recursively all the way from the root.
      // This way, the condition "lastFileItem==nil" signals that the array
      // is empty.
      [self fillCacheToItem: parentDirectory];
    }

    // Cache is currently filled to parent directory. Use it to construct
    // new path.
    pathString = [[cachedPathStrings lastObject] 
                    stringByAppendingPathComponent: [item name]];
  }

  
  if (! [item isPlainFile]) {
    if (addTrailingSlashToDirectoryPaths) {
      pathString = [pathString stringByAppendingString: @"/"];
    }
    
    // Only cache path names for directories.
    [cachedPathStrings addObject: pathString];
    [lastFileItem release];
    lastFileItem = [item retain];
  }
  
  return pathString;
}

- (void) clearCache {
  [cachedPathStrings removeAllObjects];
  [lastFileItem release];
  lastFileItem = nil;
}

@end


@implementation FileItemPathStringCache (PrivateMethods)

- (void) fillCacheToItem: (FileItem *) item {
  NSAssert(item != nil, @"Item must be non-nil.");
  
  NSString  *pathString;
  NSString*  comp = [item isSpecial] ? @"" : [item name];
  if ([item parentDirectory] != nil) {
    [self fillCacheToItem: [item parentDirectory]];
    pathString = 
      [[cachedPathStrings lastObject] stringByAppendingPathComponent: comp];
  }
  else {
    pathString = comp;
    NSAssert([cachedPathStrings count] == 0, @"Cache should be empty.");
  }
  
  if (addTrailingSlashToDirectoryPaths) {
    pathString = [pathString stringByAppendingString: @"/"];
  }
  
  [cachedPathStrings addObject: pathString];
  [lastFileItem release];
  lastFileItem = [item retain];
}

@end
