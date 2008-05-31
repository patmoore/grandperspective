#import "StringContainmentTest.h"


@implementation StringContainmentTest

- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  [dict setObject: @"StringContainmentTest" forKey: @"class"];
}


- (BOOL) testString: (NSString *)string matches: (NSString *)match {
  return [string rangeOfString: match
                   options: (caseSensitive ? 0 : NSCaseInsensitiveSearch)
                   ].location != NSNotFound;
}

- (NSString*) descriptionFormat {
  return 
    ( caseSensitive
      ? NSLocalizedStringFromTable( 
          @"%@ conTains %@", @"Tests",
          @"Case-sensitive string test with 1: subject, and 2: match targets" )
      : NSLocalizedStringFromTable( 
          @"%@ contains %@", @"Tests",
          @"String test with 1: subject, and 2: match targets" ) );
}


+ (NSObject *) objectFromDictionary: (NSDictionary *)dict {
  NSAssert([[dict objectForKey: @"class"] 
             isEqualToString: @"StringContainmentTest"],
             @"Incorrect value for class in dictionary.");

  return [[[StringContainmentTest alloc] initWithPropertiesFromDictionary: dict]
           autorelease];
}

@end
