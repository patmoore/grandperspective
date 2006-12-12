#import "StringContainmentTest.h"


@implementation StringContainmentTest

- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  [dict setObject: @"StringContainmentTest" forKey: @"class"];
}


- (BOOL) testString:(NSString*)string matches:(NSString*)match {
  return [string rangeOfString:match].location != NSNotFound;
}

- (NSString*) descriptionFormat {
  return NSLocalizedStringFromTable( 
           @"%@ contains %@", @"tests",
           @"String test with 1: subject, and 2: match targets" );
}


+ (NSObject *) objectFromDictionary: (NSDictionary *)dict {
  NSAssert([[dict objectForKey: @"class"] 
             isEqualToString: @"StringContainmentTest"],
             @"Incorrect value for class in dictionary.");

  return [[[StringContainmentTest alloc] initWithPropertiesFromDictionary: dict]
           autorelease];
}

@end
