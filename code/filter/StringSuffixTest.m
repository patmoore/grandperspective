#import "StringSuffixTest.h"


@implementation StringSuffixTest

- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  [dict setObject: @"StringSuffixTest" forKey: @"class"];
}


- (BOOL) testString: (NSString *)string matches: (NSString *)match {
  int  stringLen = [string length];
  int  matchLen = [match length];
  
  if (stringLen < matchLen) {
    return NO;
  }
  else {
    return [string compare: match 
                     options: (caseSensitive ? 0 : NSCaseInsensitiveSearch)
                     range: NSMakeRange( stringLen - matchLen, matchLen)
                     ] == NSOrderedSame;
  }
}

- (NSString*) descriptionFormat {
  return 
    ( caseSensitive
      ? NSLocalizedStringFromTable( 
          @"%@ enDs with %@", @"Tests",
          @"Case-sensitive string test with 1: subject, and 2: match targets" )
      : NSLocalizedStringFromTable( 
          @"%@ ends with %@", @"Tests",
          @"String test with 1: subject, and 2: match targets" ) );
}


+ (NSObject *) objectFromDictionary: (NSDictionary *)dict {
  NSAssert([[dict objectForKey: @"class"] 
             isEqualToString: @"StringSuffixTest"],
             @"Incorrect value for class in dictionary.");

  return [[[StringSuffixTest alloc] initWithPropertiesFromDictionary: dict]
           autorelease];
}

@end
