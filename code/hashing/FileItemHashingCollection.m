#import "FileItemHashingCollection.h"

#import "PlainFileItem.h"
#import "DirectoryItem.h"

#import "StatelessFileItemHashing.h"
#import "UniformTypeHashingScheme.h"

@interface HashingByDepth : StatelessFileItemHashing {
}
@end

@interface HashingByExtension : StatelessFileItemHashing {
}
@end

@interface HashingByFilename : StatelessFileItemHashing {
}
@end

@interface HashingByDirectoryName : StatelessFileItemHashing {
}
@end

@interface HashingByTopDirectoryName : StatelessFileItemHashing {
}
@end

@implementation HashingByDepth

- (int) hashForFileItem: (PlainFileItem *)item atDepth: (int) depth {
  return depth;
}

- (int) hashForFileItem: (PlainFileItem *)item inTree: (FileItem *)treeRoot {
  // Establish the depth of the file item in the tree.
  FileItem  *fileItem = item;
  int  depth = 0;
  
  while (fileItem != treeRoot) {
    fileItem = [fileItem parentDirectory];
    depth++;
    
    NSAssert(item != nil, @"Failed to encounter treeRoot");
  }
  
  return depth;
}


- (BOOL) canProvideLegend {
  return YES;
}

//----------------------------------------------------------------------------
// Implementation of informal LegendProvidingFileItemHashing protocol

- (NSString *) descriptionForHash: (int)hash {
  if (hash == 0) {
    return NSLocalizedString(@"Outermost level", 
                             @"Legend for Level mapping scheme.");
  }
  else {
    NSString  
      *fmt = NSLocalizedString(@"Level %d", 
                               @"Legend for Level mapping scheme.");
    return [NSString stringWithFormat: fmt, hash];
  }
}

- (NSString *) descriptionForRemainingHashes {
  return NSLocalizedString(@"Lower levels",
                           @"Misc. description for Level mapping scheme.");
}

@end // @implementation HashingByDepth


@implementation HashingByExtension

- (int) hashForFileItem: (PlainFileItem *)item atDepth: (int) depth {
  return [[[item name] pathExtension] hash];
}

@end // @implementation HashingByExtension


@implementation HashingByFilename

- (int) hashForFileItem: (PlainFileItem *)item atDepth: (int) depth {
  return [[item name] hash];
}

@end // @implementation HashingByFilename


@implementation HashingByDirectoryName

- (int) hashForFileItem: (PlainFileItem *)item atDepth: (int) depth {
  return [[[item parentDirectory] name] hash];
}

@end // @implementation HashingByDirectoryName 


@implementation HashingByTopDirectoryName

- (int) hashForFileItem: (PlainFileItem *)item atDepth: (int) depth {
  if (depth == 0) {
    return [[item name] hash];
  }

  DirectoryItem  *dir = [item parentDirectory];
  int  i = depth-2;

  while (--i >= 0) {
    dir = [dir parentDirectory];
  }

  return [[dir name] hash];
}

- (int) hashForFileItem: (PlainFileItem *)item inTree: (FileItem *)treeRoot {
  if (item == treeRoot) {
    return [[item name] hash];
  }
  
  DirectoryItem  *dir = [item parentDirectory];  
  DirectoryItem  *oldDir = dir;
  while (dir != treeRoot) {
    oldDir = dir;
    dir = [dir parentDirectory];
    NSAssert(dir != nil, @"Failed to encounter treeRoot");
  }
  
  return [[oldDir name] hash];
}

@end // @implementation HashingByTopDirectoryName 


@implementation FileItemHashingCollection

+ (FileItemHashingCollection*) defaultFileItemHashingCollection {
  static  FileItemHashingCollection  
    *defaultFileItemHashingCollectionInstance = nil;

  if (defaultFileItemHashingCollectionInstance==nil) {
    FileItemHashingCollection  *instance = 
      [[[FileItemHashingCollection alloc] init] autorelease];
    
    [instance addFileItemHashingScheme:
                  [[[HashingByTopDirectoryName alloc] init] autorelease]
                key: @"top folder"];
    [instance addFileItemHashingScheme:
                  [[[HashingByDirectoryName alloc] init] autorelease]
                key: @"folder"];
    [instance addFileItemHashingScheme:
                  [[[HashingByExtension alloc] init] autorelease]
                key: @"extension"];
    [instance addFileItemHashingScheme:
                  [[[HashingByFilename alloc] init] autorelease]
                key: @"name"];
    [instance addFileItemHashingScheme:
                  [[[HashingByDepth alloc] init] autorelease]
                key: @"level"];
    [instance addFileItemHashingScheme:
                  [[[StatelessFileItemHashing alloc] init] autorelease]
                key: @"nothing"];
    [instance addFileItemHashingScheme:
                  [[[UniformTypeHashingScheme alloc] init] autorelease]
                key: @"uniform type"];

    defaultFileItemHashingCollectionInstance = [instance retain];
  }
  
  return defaultFileItemHashingCollectionInstance;
}

// Overrides super's designated initialiser.
- (id) init {
  return [self initWithDictionary:
                   [NSMutableDictionary dictionaryWithCapacity: 8]];
}

- (id) initWithDictionary: (NSDictionary *)dictionary {
  if (self = [super init]) {
    schemesDictionary = [dictionary retain];
  }
  return self;
}

- (void) dealloc {
  [schemesDictionary release];
  
  [super dealloc];
}

- (void) addFileItemHashingScheme: (NSObject <FileItemHashingScheme> *)scheme 
           key: (NSString *)key {
  [schemesDictionary setObject: scheme forKey: key];
}

- (void) removeFileItemHashingSchemeForKey: (NSString *)key {
  [schemesDictionary removeObjectForKey: key];
}

- (NSArray*) allKeys {
  return [schemesDictionary allKeys];
}

- (NSObject <FileItemHashingScheme> *) fileItemHashingSchemeForKey: 
                                                              (NSString *)key {
  return [schemesDictionary objectForKey: key];
}

@end // @implementation FileItemHashingCollection
