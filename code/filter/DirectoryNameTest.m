#import "DirectoryNameTest.h"


@implementation DirectoryNameTest

- (BOOL) testFileItem:(FileItem*)item {
  return (![item isPlainFile] && [stringTest testString:[item name]]);
}

- (NSString*) subjectDescription {
  return @"folder name";
}

@end
