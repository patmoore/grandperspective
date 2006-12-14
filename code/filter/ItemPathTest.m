#import "ItemPathTest.h"

#import "DirectoryItem.h"
#import "StringTest.h"


@interface ItemPathTest (PrivateMethods)

- (NSMutableString*) stringForFileItemPath:(FileItem*)item;

@end

@implementation ItemPathTest

- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  [dict setObject: @"ItemPathTest" forKey: @"class"];
}


- (BOOL) testFileItem: (FileItem *)item {
  return [stringTest testString: 
            [[item parentDirectory] stringForFileItemPath]];
}

- (NSString*) description {
  NSString  *subject = 
    NSLocalizedStringFromTable( @"path" , @"tests", 
                                @"A pathname as the subject of a string test" );

  return [stringTest descriptionWithSubject: subject];
}


+ (NSObject *) objectFromDictionary: (NSDictionary *)dict {
  NSAssert([[dict objectForKey: @"class"] isEqualToString: @"ItemPathTest"],
             @"Incorrect value for class in dictionary.");

  return [[[ItemPathTest alloc] initWithPropertiesFromDictionary: dict]
           autorelease];
}

@end