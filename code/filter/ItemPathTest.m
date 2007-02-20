#import "ItemPathTest.h"

#import "DirectoryItem.h"
#import "StringTest.h"
#import "FileItemPathStringCache.h"

@implementation ItemPathTest

- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  [dict setObject: @"ItemPathTest" forKey: @"class"];
}


- (BOOL) testFileItem: (FileItem *)item context: (id)context {
  return [stringTest testString: 
            [context pathStringForFileItem: [item parentDirectory]]];
  // Note: For performance reasons, it does not get the string for the item's 
  // path from the item itself, but uses the context instead. The context, it 
  // is assumed, supports the pathStringForFileItem: method as provided by the 
  // FileItemPathStringCache class. This way, path items do not constantly need
  // to be rebuilt from scratch, nor do they need to be maintained longer than 
  // needed.
}

- (NSString*) description {
  NSString  *subject = 
    NSLocalizedStringFromTable( @"path" , @"Tests", 
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
