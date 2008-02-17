#import "UniformTypeInventory.h"

#import "FileItem.h"
#import "UniformType.h"


@implementation UniformTypeInventory

+ (UniformTypeInventory *)defaultUniformTypeInventory {
  static UniformTypeInventory
    *defaultUniformTypeInventoryInstance = nil;

  if (defaultUniformTypeInventoryInstance==nil) {
    defaultUniformTypeInventoryInstance = [[UniformTypeInventory alloc] init];
  }
  
  return defaultUniformTypeInventoryInstance;
}


// Overrides super's designated initialiser.
- (id) init {
  if (self = [super init]) {
    typeForExtension = [[NSMutableDictionary alloc] initWithCapacity: 32];
    untypedExtensions = [[NSMutableSet alloc] initWithCapacity: 32];
    typeForUTI = [[NSMutableDictionary alloc] initWithCapacity: 32];
    parentlessTypes = [[NSMutableSet alloc] initWithCapacity: 8];
  }
  
  return self;
}

- (void) dealloc {
  [typeForExtension release];
  [untypedExtensions release];
  [typeForUTI release];
  [parentlessTypes release];
    
  [super dealloc];
}


- (NSEnumerator *)uniformTypeEnumerator {
  return [typeForUTI objectEnumerator];
}


- (void) registerFileItem: (FileItem *)item {
  // Implicitly registers type for the file (if any)
  [self uniformTypeForFileItem: item];
}

- (UniformType *)uniformTypeForFileItem: (FileItem *)item {
  NSString  *ext = [[item name] pathExtension];
  
  UniformType  *type = [typeForExtension objectForKey: ext];
  if (type != nil) {
    // The extension was already encountered, and corresponds to a valid UTI.
    return type;
  }
  
  if ([untypedExtensions containsObject: ext]) {
    // The extension was already encountered, and has no proper UTI associated
    // with it.
    return nil;
  }

  NSString  *uti = 
    (NSString*) UTTypeCreatePreferredIdentifierForTag
                  (kUTTagClassFilenameExtension, (CFStringRef)ext, NULL); 
    // TODO: Use "kUTTypeData" in Mac OS X 10.4 and up.  

  if ([uti hasPrefix: @"dyn."]) {
    [untypedExtensions addObject: ext];
    return nil;
  }
  else {
    type = [self uniformTypeForIdentifier: uti];
    
    [typeForExtension setObject: type forKey: ext];
    
    return type;
  }
}

- (UniformType *)uniformTypeForIdentifier: (NSString *)uti {
  UniformType  *type = [typeForUTI objectForKey: uti];

  if (type != nil) {
    // It has already been registered
    return type;
  }

  NSLog(@"Registering file type %@", uti);
  
  type = [[UniformType alloc] initWithUniformTypeIdentifier: uti 
                                inventory: self];
  [typeForUTI setObject: type forKey: uti];
  
  // Register as a child to each parent
  NSEnumerator  *parentEnum = [[type parentTypes] objectEnumerator];
  UniformType  *parentType;
  while (parentType = [parentEnum nextObject]) {
    [parentType addChildType: type];
  }
  
  return type;
}


- (void) dumpTypesToLog {
  NSEnumerator  *typesEnum = [self uniformTypeEnumerator];
  UniformType  *type;
  while (type = [typesEnum nextObject]) {
    NSLog(@"Type: %@", [type uniformTypeIdentifier]);
    NSLog(@"  Description: %@", [type description]);

    NSMutableString  *s = [NSMutableString stringWithCapacity: 64];
    NSEnumerator  *typesEnum2 = [[type parentTypes] objectEnumerator];
    UniformType  *type2;
    while (type2 = [typesEnum2 nextObject]) {
      [s appendFormat: @" %@", [type2 uniformTypeIdentifier]];
    }
    NSLog(@"  Parents:%@", s);
    
    [s deleteCharactersInRange: NSMakeRange(0, [s length])];
    typesEnum2 = [[type childTypes] objectEnumerator];
    while (type2 = [typesEnum2 nextObject]) {
      [s appendFormat: @" %@", [type2 uniformTypeIdentifier]];
    }
    NSLog(@"  Children:%@", s);
  }
}  

      
@end // @implementation UniformTypeInventory


