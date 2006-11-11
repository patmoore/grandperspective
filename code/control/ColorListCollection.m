#import "ColorListCollection.h"


static ColorListCollection  *defaultInstance = nil;

@implementation ColorListCollection

+ (ColorListCollection*) defaultColorListCollection {
  if (defaultInstance == nil) {
    defaultInstance = [[ColorListCollection alloc] init];
    
    NSBundle  *bundle = [NSBundle mainBundle];
    //NSLog( @"Main bundle: %@", bundle );
    //NSLog( @"Path: %@", [bundle bundlePath] );
    NSArray  *colorListPaths = [bundle pathsForResourcesOfType: @".clr"
                                          inDirectory: nil];
    NSEnumerator  *pathEnum = [colorListPaths objectEnumerator];
    NSString  *path;
    while (path = [pathEnum nextObject]) {
      NSLog( @"Color list : %@", path );

      NSString  *name = 
        [[path lastPathComponent] stringByDeletingPathExtension];

      NSLog( @"Name: %@", name );

      NSColorList  *colorList = 
        [[NSColorList alloc] initWithName: name fromFile: path];
         
      [defaultInstance addColorList: colorList key: name];
    }
  }
  
  return defaultInstance;
}


// Overrides designated initialiser.
- (id) init {
  if (self = [super init]) {
    colorListDictionary = [[NSMutableDictionary alloc] initWithCapacity:8];
  }
  
  return self;
}

- (void) dealloc {
  [colorListDictionary release];
  [defaultKey release];

  [super dealloc];
}


- (void) addColorList: (NSColorList *)colorList key: (NSString *)key {
  if (defaultKey == nil) {
    [self setKeyForDefaultColorList: key];
  }
  [colorListDictionary setObject: colorList forKey: key];
}

- (void) removeColorListForKey: (NSString *)key {
  [colorListDictionary removeObjectForKey: key];
}

- (void) setKeyForDefaultColorList: (NSString *)key {
  if (key != defaultKey) {
    [defaultKey release];
    defaultKey = [key retain];
  }
}


- (NSArray*) allKeys {
  return [colorListDictionary allKeys];
}

- (NSString*) keyForDefaultColorList {
  return defaultKey;
}

- (NSColorList*) colorListForKey: (NSString *)key {
  return [colorListDictionary objectForKey:key];
}

@end
