#import "ItemNameTest.h"

#import "FileItem.h"
#import "StringTest.h"


@implementation ItemNameTest 

- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  [dict setObject: @"ItemNameTest" forKey: @"class"];
}


- (BOOL) testFileItem: (FileItem *)item context: (id)context {
  return [stringTest testString: [item name]];
}

- (NSString*) description {
  NSString  *subject = 
    NSLocalizedStringFromTable( @"name" , @"tests", 
                                @"A filename as the subject of a string test" );

  return [stringTest descriptionWithSubject: subject];
}


+ (NSObject *) objectFromDictionary: (NSDictionary *)dict {
  NSAssert([[dict objectForKey: @"class"] isEqualToString: @"ItemNameTest"],
             @"Incorrect value for class in dictionary.");

  return [[[ItemNameTest alloc] initWithPropertiesFromDictionary: dict]
           autorelease];
}

@end