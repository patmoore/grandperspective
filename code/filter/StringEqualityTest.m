#import "StringEqualityTest.h"


@implementation StringEqualityTest

- (BOOL) testString:(NSString*)string matches:(NSString*)match {
  return [string isEqualToString:match];
}

- (NSString*) descriptionOfTest {
  return @"equals";
}

@end
