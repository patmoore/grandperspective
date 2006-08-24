#import "StringContainmentTest.h"


@implementation StringContainmentTest

- (BOOL) testString:(NSString*)string matches:(NSString*)match {
  return [string rangeOfString:match].location != NSNotFound;
}

- (NSString*) descriptionFormat {
  return NSLocalizedStringFromTable( 
           @"%@ contains %@", @"tests",
           @"String test with 1: subject, and 2: match targets" );
}

@end
