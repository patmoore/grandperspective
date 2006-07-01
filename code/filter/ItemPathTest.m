#import "ItemPathTest.h"

#import "FileItem.h"
#import "StringTest.h"


@interface ItemPathTest (PrivateMethods)

- (NSMutableString*) stringForFileItemPath:(FileItem*)item;

@end

@implementation ItemPathTest

- (BOOL) testFileItem:(FileItem*)item {
  return [stringTest testString:[item stringForFileItemPath]];
}

- (NSString*) description {
  return [stringTest descriptionWithSubject:@"path"];
}

@end