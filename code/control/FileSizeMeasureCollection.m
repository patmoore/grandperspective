#import "FileSizeMeasureCollection.h"

#import "TreeBuilder.h"

@implementation FileSizeMeasureCollection

+ (void) initialize {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  NSDictionary *appDefaults = 
    [NSDictionary
       dictionaryWithObject: @"logical" forKey: @"fileSizeMeasure"];

  [defaults registerDefaults: appDefaults];
}


+ (FileSizeMeasureCollection*) defaultFileSizeMeasureCollection {
  static  FileSizeMeasureCollection  
    *defaultFileSizeMeasureCollectionInstance = nil;

  if (defaultFileSizeMeasureCollectionInstance == nil) {
    defaultFileSizeMeasureCollectionInstance = 
      [[FileSizeMeasureCollection alloc] initWithDictionary:
          [NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithInt: LOGICAL_FILE_SIZE], @"logical",
             [NSNumber numberWithInt: PHYSICAL_FILE_SIZE], @"physical", 
             nil]];
  }
  
  return defaultFileSizeMeasureCollectionInstance;
}


// Overrides designated initialiser
- (id) init {
  return [self initWithDictionary: [NSDictionary dictionary]];
}

- (id) initWithDictionary: (NSDictionary *)dict {
  if (self = [super init]) {
    dictionary = [dict retain];
  }
  return self;
}

- (void) dealloc {
  [dictionary release];
  
  [super dealloc];
}


- (NSArray*) allKeys {
  return [dictionary allKeys];
}

- (int) fileSizeMeasureForKey: (NSString *)key {
  return [[dictionary objectForKey: key] intValue];
}

@end
