#import "FileItemMappingCollection.h"

#import "PlainFileItem.h"
#import "DirectoryItem.h"

#import "StatelessFileItemMapping.h"
#import "UniformTypeMappingScheme.h"

@interface MappingByLevel : StatelessFileItemMapping {
}
@end

@interface MappingByExtension : StatelessFileItemMapping {
}
@end

@interface MappingByFilename : StatelessFileItemMapping {
}
@end

@interface MappingByDirectoryName : StatelessFileItemMapping {
}
@end

@interface MappingByTopDirectoryName : StatelessFileItemMapping {
}
@end

@implementation MappingByLevel

- (int) hashForFileItem: (PlainFileItem *)item atDepth: (int) depth {
  return depth;
}

- (int) hashForFileItem: (PlainFileItem *)item inTree: (FileItem *)treeRoot {
  // Establish the depth of the file item in the tree.

  // Matching parent directories as a stop-criterion, as opposed to matching
  // the file items directly. The reason is that when the item is at depth 0, 
  // it does not necessarily equal the treeRoot; When package contents are 
  // hidden, a stand-in item is used for directory items that are packages.
  
  FileItem  *fileItem = [item parentDirectory];
  FileItem  *itemToMatch = [treeRoot parentDirectory];
  int  depth = 0;
  
  while (fileItem != itemToMatch) {
    fileItem = [fileItem parentDirectory];
    depth++;
    
    NSAssert(fileItem != nil, @"Failed to encounter treeRoot");
  }
  
  return depth;
}


- (BOOL) canProvideLegend {
  return YES;
}

//----------------------------------------------------------------------------
// Implementation of informal LegendProvidingFileItemMapping protocol

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

@end // @implementation MappingByLevel


@implementation MappingByExtension

- (int) hashForFileItem: (PlainFileItem *)item atDepth: (int) depth {
  return [[[item name] pathExtension] hash];
}

@end // @implementation MappingByExtension


@implementation MappingByFilename

- (int) hashForFileItem: (PlainFileItem *)item atDepth: (int) depth {
  return [[item name] hash];
}

@end // @implementation MappingByFilename


@implementation MappingByDirectoryName

- (int) hashForFileItem: (PlainFileItem *)item atDepth: (int) depth {
  return [[[item parentDirectory] name] hash];
}

@end // @implementation MappingByDirectoryName 


@implementation MappingByTopDirectoryName

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

@end // @implementation MappingByTopDirectoryName 


@implementation FileItemMappingCollection

+ (FileItemMappingCollection*) defaultFileItemMappingCollection {
  static  FileItemMappingCollection  
    *defaultFileItemMappingCollectionInstance = nil;

  if (defaultFileItemMappingCollectionInstance==nil) {
    FileItemMappingCollection  *instance = 
      [[[FileItemMappingCollection alloc] init] autorelease];
    
    [instance addFileItemMappingScheme:
                  [[[MappingByTopDirectoryName alloc] init] autorelease]
                key: @"top folder"];
    [instance addFileItemMappingScheme:
                  [[[MappingByDirectoryName alloc] init] autorelease]
                key: @"folder"];
    [instance addFileItemMappingScheme:
                  [[[MappingByExtension alloc] init] autorelease]
                key: @"extension"];
    [instance addFileItemMappingScheme:
                  [[[MappingByFilename alloc] init] autorelease]
                key: @"name"];
    [instance addFileItemMappingScheme:
                  [[[MappingByLevel alloc] init] autorelease]
                key: @"level"];
    [instance addFileItemMappingScheme:
                  [[[StatelessFileItemMapping alloc] init] autorelease]
                key: @"nothing"];
    [instance addFileItemMappingScheme:
                  [[[UniformTypeMappingScheme alloc] init] autorelease]
                key: @"uniform type"];

    defaultFileItemMappingCollectionInstance = [instance retain];
  }
  
  return defaultFileItemMappingCollectionInstance;
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

- (void) addFileItemMappingScheme: (NSObject <FileItemMappingScheme> *)scheme 
           key: (NSString *)key {
  [schemesDictionary setObject: scheme forKey: key];
}

- (void) removeFileItemMappingSchemeForKey: (NSString *)key {
  [schemesDictionary removeObjectForKey: key];
}

- (NSArray*) allKeys {
  return [schemesDictionary allKeys];
}

- (NSObject <FileItemMappingScheme> *) fileItemMappingSchemeForKey: 
                                                              (NSString *)key {
  return [schemesDictionary objectForKey: key];
}

@end // @implementation FileItemMappingCollection
