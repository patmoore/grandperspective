#import "FileNameTest.h"


@implementation FileNameTest

- (BOOL) testFileItem:(FileItem*)item {
  return ([item isPlainFile] && [stringTest testString:[item name]]);
}

- (NSString*) subjectDescription {
  return @"filename";
}

@end
