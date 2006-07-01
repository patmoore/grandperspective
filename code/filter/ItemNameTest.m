#import "ItemNameTest.h"

#import "FileItem.h"
#import "StringTest.h"


@implementation ItemNameTest 

- (BOOL) testFileItem:(FileItem*)item {
  return [stringTest testString:[item name]];
}

- (NSString*) description {
  return [stringTest descriptionWithSubject:@"name"];
}

@end