#import "ItemNameTest.h"

#import "FileItem.h"
#import "StringTest.h"


@implementation ItemNameTest 

- (BOOL) testFileItem:(FileItem*)item {
  return [stringTest testString:[item name]];
}

- (NSString*) description {
  NSString  *subject = 
    NSLocalizedStringFromTable( @"name" , @"tests", 
                                @"A filename as the subject of a string test" );

  return [stringTest descriptionWithSubject: subject];
}

@end