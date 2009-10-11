#import <Cocoa/Cocoa.h>

#import "FileItemTest.h"


@interface ItemTypeTest : FileItemTest {

  // Array of UniformTypes
  NSArray  *matches;
  
  // Conrols if the matching is strict, or if conformance is tested.
  BOOL  strict;

}

- (id) initWithMatchTargets:(NSArray *)matches;

- (id) initWithMatchTargets:(NSArray *)matches strict:(BOOL) strict;


- (NSArray *)matchTargets;
- (BOOL) isStrict;

+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict;

@end
