#import "StringTest.h"

#import "StringPrefixTest.h"
#import "StringSuffixTest.h"
#import "StringEqualityTest.h"
#import "StringContainmentTest.h"


@implementation StringTest

+ (StringTest *)stringTestFromDictionary:(NSDictionary *)dict {
  NSString  *classString = [dict objectForKey: @"class"];
  
  if ([classString isEqualToString: @"StringContainmentTest"]) {
    return [StringContainmentTest stringTestFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"StringSuffixTest"]) {
    return [StringSuffixTest stringTestFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"StringPrefixTest"]) {
    return [StringPrefixTest stringTestFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"StringEqualityTest"]) {
    return [StringEqualityTest stringTestFromDictionary: dict];
  }

  NSAssert1(NO, @"Unrecognized string test class \"%@\".", classString);
}

@end


@implementation StringTest (ProtectedMethods)

/* Initialiser used when the test is restored from a dictionary.
 *
 * Note: Special case. Does not call own designated initialiser. It should
 * be overridden and only called by initialisers with the same signature.
 */
- (id) initWithPropertiesFromDictionary:(NSDictionary *)dict {
  if (self = [super init]) {
    // void
  }
  
  return self;
}

- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  // void
}

@end
