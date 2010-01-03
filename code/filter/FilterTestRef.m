#import "FilterTestRef.h"


@implementation FilterTestRef

+ (id) filterTestWithName:(NSString *)name {
  return [[[FilterTestRef alloc] initWithName: name] autorelease];
}

+ (id) filterTestWithName:(NSString *)name inverted:(BOOL) inverted {
  return [[[FilterTestRef alloc] initWithName: name inverted: inverted] 
              autorelease];
}


+ (FilterTestRef *)filterTestRefFromDictionary:(NSDictionary *)dict {
  return 
    [FilterTestRef filterTestWithName: [dict objectForKey: @"name"]
                     inverted: [[dict objectForKey: @"inverted"] boolValue]];
}


// Overrides designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithName: instead.");
}

- (id) initWithName:(NSString *)nameVal {
  return [self initWithName: nameVal inverted: NO];
}

- (id) initWithName:(NSString *)nameVal inverted:(BOOL) invertedVal {
  if (self = [super init]) {
    name = [[NSString alloc] initWithString: nameVal]; // Ensure it's immutable
    inverted = invertedVal;
  }

  return self;
}

- (void) dealloc {
  [name release];
  
  [super dealloc];
}


- (NSString *) name {
  return name;
}

- (BOOL) isInverted {
  return inverted;
}


- (NSDictionary *)dictionaryForObject {
  return [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithBool: inverted], @"inverted",                         name, @"name",
                         nil];
}

@end // @implementation FilterTestRef
