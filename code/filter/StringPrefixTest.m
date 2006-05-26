#import "StringPrefixTest.h"


@implementation StringPrefixTest

- (BOOL) testString:(NSString*)string matches:(NSString*)match {
  return [string hasPrefix:match];
}

- (NSString*) descriptionOfTest {
  return @"starts with";
}

@end
