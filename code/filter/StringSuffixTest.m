#import "StringSuffixTest.h"


@implementation StringSuffixTest

- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  [dict setObject: @"StringSuffixTest" forKey: @"class"];
}


- (BOOL) testString:(NSString*)string matches:(NSString*)match {
  return [string hasSuffix:match];
}

- (NSString*) descriptionFormat {
  return NSLocalizedStringFromTable( 
           @"%@ ends with %@", @"tests",
           @"String test with 1: subject, and 2: match targets" );
}


+ (NSObject *) objectFromDictionary: (NSDictionary *)dict {
  NSAssert([[dict objectForKey: @"class"] 
             isEqualToString: @"StringSuffixTest"],
             @"Incorrect value for class in dictionary.");

  return [[[StringSuffixTest alloc] initWithPropertiesFromDictionary: dict]
           autorelease];
}

@end
