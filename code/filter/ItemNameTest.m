#import "ItemNameTest.h"

#import "FileItem.h"
#import "StringTest.h"
#import "FileItemTestVisitor.h"


@implementation ItemNameTest 

- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  [dict setObject: @"ItemNameTest" forKey: @"class"];
}


- (TestResult) testFileItem: (FileItem *)item context: (id)context {
  return ([stringTest testString: [item name]] ? TEST_PASSED : TEST_FAILED);
}

- (void) acceptFileItemTestVisitor: (NSObject <FileItemTestVisitor> *)visitor {
  [visitor visitItemNameTest: self];
}


- (NSString *) description {
  NSString  *subject = 
    NSLocalizedStringFromTable( @"name" , @"Tests", 
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
