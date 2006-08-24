#import "StringSuffixTest.h"


@implementation StringSuffixTest

- (BOOL) testString:(NSString*)string matches:(NSString*)match {
  return [string hasSuffix:match];
}

- (NSString*) descriptionFormat {
  return NSLocalizedStringFromTable( 
           @"%@ ends with %@", @"tests",
           @"String test with 1: subject, and 2: match targets" );
}

@end
