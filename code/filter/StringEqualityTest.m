#import "StringEqualityTest.h"


@implementation StringEqualityTest

- (BOOL) testString:(NSString*)string matches:(NSString*)match {
  return [string isEqualToString:match];
}

- (NSString*) descriptionFormat {
  return NSLocalizedStringFromTable( 
           @"%@ equals %@", @"tests",
           @"String test with 1: subject, and 2: match targets" );
}

@end
