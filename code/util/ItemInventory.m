#import "ItemInventory.h"

#import "FileItem.h"

@interface ItemInventory (PrivateMethods)

- (NSString *) stringForSet: (NSSet *)set;

@end

@implementation ItemInventory

- (id) init {
  if (self = [super init]) {
    typedExtensions = [[NSMutableSet alloc] initWithCapacity: 32];
    untypedExtensions = [[NSMutableSet alloc] initWithCapacity: 32];
    fileTypes = [[NSMutableSet alloc] initWithCapacity: 32];
  }
  
  return self;
}

- (void) dealloc {
  [typedExtensions release];
  [untypedExtensions release];
  [fileTypes release];
    
  [super dealloc];
}


- (void) registerFileItem: (FileItem *)item {
  NSString  *ext = [[item name] pathExtension];
  
  NSMutableSet  *extSet = NULL;
  if ([typedExtensions containsObject:ext]) {
    extSet = typedExtensions;
  }
  else if ([untypedExtensions containsObject:ext]) {
    extSet = untypedExtensions;
  }
  else {
    NSString*  utiTypeString = 
      (NSString*) UTTypeCreatePreferredIdentifierForTag
        (kUTTagClassFilenameExtension, (CFStringRef)ext, NULL); 
        // TODO: Use "kUTTypeData" in Mac OS X 10.4 and up.
      
    if ([utiTypeString hasPrefix: @"dyn."]) {
      extSet = untypedExtensions;
    }
    else {
      extSet = typedExtensions;
      [fileTypes addObject: utiTypeString];
    }

    [extSet addObject: ext];
  }
  
  if (extSet == typedExtensions) {
    numTyped++;
    totalSizeTyped += [item itemSize];
  }
  else {
    numUntyped++;
    totalSizeUntyped += [item itemSize];
  }
}

- (void) dumpItemReport {
  NSLog(@"FILE TYPE SUMMARY\n%d typed files, total size=%qu.\n%d untyped files, total size=%qu.\n", 
          numTyped, totalSizeTyped, numUntyped, totalSizeUntyped);
  
  NSLog(@"Encountered filetypes:\n%@", [self stringForSet: fileTypes]);
  
  NSLog(@"Recognized extensions:\n%@", [self stringForSet: typedExtensions]);

  NSLog(@"Unrecognized extensions:\n%@", 
          [self stringForSet: untypedExtensions]);
}

@end

@implementation ItemInventory (PrivateMethods)

- (NSString *) stringForSet: (NSSet *)set {
  NSEnumerator  *objEnum = [set objectEnumerator];
  NSObject  *obj;
  NSMutableString  *s = [NSMutableString stringWithCapacity:1024];
  while (obj = [objEnum nextObject]) {
    [s appendFormat:@"%@\n", obj];
  }
  return s;
}

@end

