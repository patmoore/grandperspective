#import "FileItemHashingCollection.h"

#import "DirectoryItem.h" // Imports FileItem.h
#import "FileItemHashing.h"

@interface HashingByDepth : FileItemHashing {
}
@end

@interface HashingByExtension : FileItemHashing {
}
@end

@interface HashingByFilename : FileItemHashing {
}
@end

@interface HashingByDirectoryName : FileItemHashing {
}
@end

@interface HashingByTopDirectoryName : FileItemHashing {
}
@end

@implementation HashingByDepth

- (int) hashForFileItem:(FileItem*)item depth:(int)depth {
  return depth;
}

@end // @implementation HashingByDepth


@implementation HashingByExtension

- (int) hashForFileItem:(FileItem*)item depth:(int)depth {
  return [[[item name] pathExtension] hash];
}

@end // @implementation HashingByExtension


@implementation HashingByFilename

- (int) hashForFileItem:(FileItem*)item depth:(int)depth {
  return [[item name] hash];
}

@end // @implementation HashingByFilename


@implementation HashingByDirectoryName

- (int) hashForFileItem:(FileItem*)item depth:(int)depth {
  return [[[item parentDirectory] name] hash];
}

@end // @implementation HashingByDirectoryName 


@implementation HashingByTopDirectoryName

- (int) hashForFileItem:(FileItem*)item depth:(int)depth {
  DirectoryItem  *dir = [item parentDirectory];
  int  i = depth-2;

  while (--i >= 0) {
    dir = [dir parentDirectory];
  }

  return [[dir name] hash];
}

@end // @implementation HashingByTopDirectoryName 


@implementation FileItemHashingCollection

FileItemHashingCollection  *defaultInstance = nil;

+ (FileItemHashingCollection*) defaultFileItemHashingCollection {
  if (defaultInstance==nil) {
    defaultInstance = [[FileItemHashingCollection alloc] init];
    
    NSString  *hashByDirNameKey = @"folder";

    [defaultInstance addFileItemHashing:
                         [[[HashingByTopDirectoryName alloc] init] autorelease]
                       key: @"top folder"];
    [defaultInstance addFileItemHashing:
                         [[[HashingByDirectoryName alloc] init] autorelease]
                       key: hashByDirNameKey];
    [defaultInstance addFileItemHashing:
                         [[[HashingByExtension alloc] init] autorelease]
                       key: @"extension"];
    [defaultInstance addFileItemHashing:
                         [[[HashingByFilename alloc] init] autorelease]
                       key: @"name"];
    [defaultInstance addFileItemHashing:
                         [[[HashingByDepth alloc] init] autorelease]
                       key: @"depth"];
    [defaultInstance addFileItemHashing:
                         [[[FileItemHashing alloc] init] autorelease]
                       key: @"nothing"];

    [defaultInstance setKeyForDefaultHashing: hashByDirNameKey];
  }
  
  return defaultInstance;
}

// Overrides super's designated initialiser.
- (id) init {
  return [self initWithDictionary:
                   [NSMutableDictionary dictionaryWithCapacity: 8]];
}

- (id) initWithDictionary: (NSDictionary *)dictionary {
  // Init with arbitrary key as default
  return [self initWithDictionary: dictionary 
                 defaultKey: [[dictionary keyEnumerator] nextObject]];
}

- (id) initWithDictionary: (NSDictionary *)dictionary 
         defaultKey: (NSString *)defaultKeyVal {
  if (self = [super init]) {
    hashingDictionary = [dictionary retain];
    defaultKey = [defaultKeyVal retain];
  }
  return self;
}

- (void) dealloc {
  [hashingDictionary release];
  [defaultKey release];
  
  [super dealloc];
}

- (void) addFileItemHashing: (FileItemHashing *)hashing key: (NSString *)key {
  if (defaultKey == nil) {
    [self setKeyForDefaultHashing: key];
  }
  [hashingDictionary setObject: hashing forKey: key];
}

- (void) removeFileItemHashingForKey: (NSString *)key {
  [hashingDictionary removeObjectForKey: key];
}

- (void) setKeyForDefaultHashing: (NSString *)key {
  if (key != defaultKey) {
    [defaultKey release];
    defaultKey = [key retain];
  }
}

- (NSArray*) allKeys {
  return [hashingDictionary allKeys];
}

- (NSString*) keyForDefaultHashing {
  return defaultKey;
}

- (FileItemHashing*) fileItemHashingForKey: (NSString *)key {
  return [hashingDictionary objectForKey: key];
}

@end // @implementation FileItemHashingCollection
