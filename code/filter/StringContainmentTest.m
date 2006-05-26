#import "StringContainmentTest.h"


@implementation StringContainmentTest

- (BOOL) testString:(NSString*)string matches:(NSString*)match {
  return [string rangeOfString:match].location != NSNotFound;
}

- (NSString*) descriptionOfTest {
  return @"contains";
}

@end
