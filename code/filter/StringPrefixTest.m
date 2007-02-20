#import "StringPrefixTest.h"


@implementation StringPrefixTest

- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  [dict setObject: @"StringPrefixTest" forKey: @"class"];
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
                     range: NSMakeRange( 0, matchLen)
                     ] == NSOrderedSame;
  }
}

- (NSString*) descriptionFormat {
  return NSLocalizedStringFromTable(
           @"%@ starts with %@", @"Tests",
           @"String test with 1: subject, and 2: match targets" );
}


+ (NSObject *) objectFromDictionary: (NSDictionary *)dict {
  NSAssert([[dict objectForKey: @"class"] 
             isEqualToString: @"StringPrefixTest"],
             @"Incorrect value for class in dictionary.");

  return [[[StringPrefixTest alloc] initWithPropertiesFromDictionary: dict]
           autorelease];
}

@end
