#import "AbstractFileItemTest.h"


@implementation AbstractFileItemTest

// Note: Special case. Does not call own designated initialiser. It should
// be overridden and only called by initialisers with the same signature.
- (id) initWithPropertiesFromDictionary: (NSDictionary *)dict {
  if (self = [super init]) {
    // void
  }
  
  return self;
}

- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict {
  // void
}


- (NSDictionary *) dictionaryForObject {
  NSMutableDictionary  *dict = [NSMutableDictionary dictionaryWithCapacity: 8];
  
  [self addPropertiesToDictionary: dict];
  
  return dict;
}


- (void) acceptFileItemTestVisitor: (NSObject <FileItemTestVisitor> *)visitor {
  NSAssert(NO, @"Abstract method.");
}


- (BOOL) testFileItem: (FileItem *)item context: (id)context {
  NSAssert(NO, @"This method must be overridden.");
  return NO;
}

- (BOOL) appliesToDirectories {
  NSAssert(NO, @"This method must be overridden.");
  return NO;
}

@end // @implementation AbstractFileItemTest
