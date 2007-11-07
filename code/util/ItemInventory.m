#import "ItemInventory.h"

#import "FileItem.h"

@interface FileTypeInfo : NSObject {
  NSSet*  parents;
  NSMutableSet*  children;
  NSString*  description;
}

- (id) initWithType: (NSString *)uti;

- (NSSet *)getFileTypeParents;

- (NSSet *)getFileTypeChildren;
- (void) addChildType: (NSString *)uti;

- (NSString *)getFileTypeDescription;

@end // @interface FileTypeInfo


@interface ItemInventory (PrivateMethods)

- (FileTypeInfo *)infoForFileType: (NSString *)uti;
- (void) registerFileType: (NSString *)uti;

@end

@implementation ItemInventory

+ (ItemInventory *)defaultItemInventory {
  static ItemInventory
    *defaultItemInventoryInstance = nil;

  if (defaultItemInventoryInstance==nil) {
    defaultItemInventoryInstance = [[ItemInventory alloc] init];
  }
  
  return defaultItemInventoryInstance;
}


// Overrides super's designated initialiser.
- (id) init {
  if (self = [super init]) {
    typeForExtension = [[NSMutableDictionary alloc] initWithCapacity: 32];
    untypedExtensions = [[NSMutableSet alloc] initWithCapacity: 32];
    infoForFileType = [[NSMutableDictionary alloc] initWithCapacity: 32];
    parentlessTypes = [[NSMutableSet alloc] initWithCapacity: 8];
  }
  
  return self;
}

- (void) dealloc {
  [typeForExtension release];
  [untypedExtensions release];
  [infoForFileType release];
  [parentlessTypes release];
    
  [super dealloc];
}


- (NSEnumerator *)knownTypesEnumerator {
  return [infoForFileType keyEnumerator];
}


- (void) registerFileItem: (FileItem *)item {
  // Implicitly registers type for the file (if any)
  [self typeForFileItem: item];
}

- (NSString *)typeForFileItem: (FileItem *)item {
  NSString  *ext = [[item name] pathExtension];
  
  NSString  *uti = [typeForExtension objectForKey: ext];
  if (uti != NULL) {
    // The extension was already encountered, and corresponds to a valid UTI.
    return uti;
  }
  
  if ([untypedExtensions containsObject: ext]) {
    // The extension was already encountered, and has no proper UTI associated
    // with it.
    return NULL;
  }

  uti = (NSString*) UTTypeCreatePreferredIdentifierForTag
                      (kUTTagClassFilenameExtension, (CFStringRef)ext, NULL); 
        // TODO: Use "kUTTypeData" in Mac OS X 10.4 and up.  

  if ([uti hasPrefix: @"dyn."]) {
    [untypedExtensions addObject: ext];
    return NULL;
  }
  else {
    [typeForExtension setObject: uti forKey: ext];
    
    [self registerFileType: uti];
    return uti;
  }
}

@end // @implementation ItemInventory


@implementation ItemInventory (PrivateMethods)

- (FileTypeInfo *)infoForFileType: (NSString *)uti {
  FileTypeInfo  *info = [infoForFileType objectForKey: uti];

  if (info != NULL) {
    // It has already been registered
    return info;
  }

  NSLog(@"Registering file type %@", uti);
  
  info = [[[FileTypeInfo alloc] initWithType: uti] autorelease];
  [infoForFileType setObject: info forKey: uti];

  NSSet  *parents = [info getFileTypeParents];
  if ([parents count] == 0) {
    [parentlessTypes addObject: uti];
  }
  else {
    // Recursively register all parent file types as well.    
    NSEnumerator  *parentEnum = [parents objectEnumerator];
    NSString  *parent;
    
    while (parent = [parentEnum nextObject]) {
      FileTypeInfo  *parentInfo = [self infoForFileType: parent];
      [parentInfo addChildType: uti];
    }
  }
  
  return info;
}

- (void) registerFileType: (NSString *)uti {
  // Implicitly registers info if it was not yet available
  [self infoForFileType: uti];
}
      
@end // @implementation ItemInventory (PrivateMethods)


@implementation FileTypeInfo

// Overrides super's designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithType: instead.");  
}

- (id) initWithType: (NSString *)uti {
  if (self = [super init]) {  
    NSDictionary  *dict = 
      (NSDictionary*) UTTypeCopyDeclaration( (CFStringRef)uti );
    
    description = 
      [dict objectForKey: (NSString*)kUTTypeDescriptionKey];
    if (description == NULL) {
      description = uti;
    }
    [description retain];
    
    NSObject  *conforms = 
      [dict objectForKey: (NSString*)kUTTypeConformsToKey];
    if ([conforms isKindOfClass: [NSArray class]]) {
      parents = [NSSet setWithArray: (NSArray*) conforms];
    }
    else if ([conforms isKindOfClass: [NSString class]]) {
      parents = [NSSet setWithObject: conforms];
    }
    else {
      parents = [NSSet set];
    }
    [parents retain];
    
    children = [[NSMutableSet alloc] initWithCapacity: 4];
  }
  
  return self;
  
}

- (void) dealloc {
  [description release];
  [parents release];
  [children release];
  
  [super dealloc];
}

- (NSSet *)getFileTypeParents {
  return parents;
}

- (NSSet *)getFileTypeChildren {
  return children;
}

- (void) addChildType: (NSString *)uti {
  [children addObject: uti];
}

- (NSString *)getFileTypeDescription {
  return description;
}

@end // @implementation FileTypeInfo

