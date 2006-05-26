#import "StringSuffixTest.h"


@implementation StringSuffixTest

- (BOOL) testString:(NSString*)string matches:(NSString*)match {
  return [string hasSuffix:match];
}

- (NSString*) descriptionOfTest {
  return @"ends with";
}

@end
