#import "FilterTestRef.h"


@implementation FilterTestRef

+ (id) filterTestWithName:(NSString *)name {
  return [[[FilterTestRef alloc] initWithName: name] autorelease];
}


+ (FilterTestRef *)filterTestRefFromDictionary:(NSDictionary *)dict {
  FilterTestRef  *testRef = 
    [FilterTestRef filterTestWithName: [dict objectForKey: @"name"]];
  
  if ([testRef isInverted] != [[dict objectForKey: @"inverted"] boolValue]) {
    [testRef setCanToggleInverted: YES];
    [testRef toggleInverted];
  }
  
  [testRef setCanToggleInverted: 
             [[dict objectForKey: @"canToggleInverted"] boolValue]];

  return testRef;
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
    name = [nameVal retain];
    inverted = invertedVal;

    // Set default values
    canToggleInverted = YES;
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

- (void) setCanToggleInverted:(BOOL) flag {
  canToggleInverted = flag;
}

- (BOOL) canToggleInverted {
  return canToggleInverted;
}

- (void) toggleInverted {
  NSAssert([self canToggleInverted], @"Cannot toggle test.");
  inverted = !inverted;
}


- (NSDictionary *)dictionaryForObject {
  // TODO: Remove canToggleInverted from object. It should not be stored. 
  // Add MutableFilterTestRef, for use within EditFilterWindowControl only?
  return [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithBool: inverted], @"inverted",
                         [NSNumber numberWithBool: canToggleInverted], 
                            @"canToggleInverted", 
                         name, @"name",
                         nil];
}

@end // @implementation FilterTestRef
