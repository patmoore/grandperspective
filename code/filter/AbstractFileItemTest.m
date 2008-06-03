#import "AbstractFileItemTest.h"


@implementation AbstractFileItemTest

// Overrides designated initialiser.
- (id) init {
  if (self = [super init]) {
    name = nil; // Not strictly needed, but better "nil" it explicitly.
  }

  return self;
}

- (void) dealloc {
  [name release];
  
  [super dealloc];
}


// Note: Special case. Does not call own designated initialiser. It should
// be overridden and only called by initialisers with the same signature.
- (id) initWithPropertiesFromDictionary: (NSDictionary *)dict {
  if (self = [super init]) {
    name = [[dict objectForKey: @"name"] retain];
  }
  
  return self;
}

- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict {
  if (name != nil) {
    [dict setObject:name forKey: @"name"];
  }
}


- (NSDictionary *) dictionaryForObject {
  NSMutableDictionary  *dict = [NSMutableDictionary dictionaryWithCapacity: 8];
  
  [self addPropertiesToDictionary: dict];
  
  return dict;
}


- (void) acceptFileItemTestVisitor: (NSObject <FileItemTestVisitor> *)visitor {
  NSAssert(NO, @"Abstract method.");
}


- (void) setName:(NSString*)nameVal {
  if (nameVal != name) {
    [name release];
    name = [nameVal retain];
  }
}

- (NSString*) name {
  return name;
}

- (BOOL) testFileItem: (FileItem *)item context: (id)context {
  NSAssert(NO, @"This method must be overridden.");
  return NO;
}

@end // @implementation AbstractFileItemTest
