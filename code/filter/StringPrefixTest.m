#import "StringPrefixTest.h"


@implementation StringPrefixTest

- (BOOL) testString:(NSString*)string matches:(NSString*)match {
  return [string hasPrefix:match];
}

- (NSString*) descriptionFormat {
  return NSLocalizedStringFromTable(
           @"%@ starts with %@", @"tests",
           @"String test with 1: subject, and 2: match targets" );
}

@end
