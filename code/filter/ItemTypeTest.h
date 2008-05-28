#import <Cocoa/Cocoa.h>

#import "AbstractFileItemTest.h"


@interface ItemTypeTest : AbstractFileItemTest {

  // Array of UniformTypes
  NSArray  *matches;
  
  // Conrols if the matching is strict, or if conformance is tested.
  BOOL  strict;

}

- (id) initWithMatchTargets: (NSArray *)matches;

- (id) initWithMatchTargets: (NSArray *)matches strict: (BOOL) strict;


- (NSArray *) matchTargets;
- (BOOL) isStrict;

+ (NSObject *) objectFromDictionary: (NSDictionary *)dict;

@end
