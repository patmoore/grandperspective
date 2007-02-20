#import "StringEqualityTest.h"


@implementation StringEqualityTest

- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  [dict setObject: @"StringEqualityTest" forKey: @"class"];
}


- (BOOL) testString: (NSString *)string matches: (NSString *)match {
  if (caseSensitive) {
    return [string isEqualToString: match];
  }
  else {
    return [string caseInsensitiveCompare: match] == NSOrderedSame;
  }
}

- (NSString*) descriptionFormat {
  return NSLocalizedStringFromTable( 
           @"%@ equals %@", @"Tests",
           @"String test with 1: subject, and 2: match targets" );
}


+ (NSObject *) objectFromDictionary: (NSDictionary *)dict {
  NSAssert([[dict objectForKey: @"class"] 
             isEqualToString: @"StringEqualityTest"],
             @"Incorrect value for class in dictionary.");

  return [[[StringEqualityTest alloc] initWithPropertiesFromDictionary: dict]
           autorelease];
}

@end
