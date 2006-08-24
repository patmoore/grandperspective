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
  NSString  *subject = 
    NSLocalizedStringFromTable( @"path" , @"tests", 
                                @"A pathname as the subject of a string test" );

  return [stringTest descriptionWithSubject: subject];
}

@end