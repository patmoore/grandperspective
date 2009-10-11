#import "FileItemTest.h"

#import "FileItemTest.h"
#import "ItemNameTest.h"
#import "ItemPathTest.h"
#import "ItemSizeTest.h"
#import "ItemTypeTest.h"
#import "ItemFlagsTest.h"
#import "SelectiveItemTest.h"
#import "CompoundAndItemTest.h"
#import "CompoundOrItemTest.h"
#import "NotItemTest.h"


@implementation FileItemTest

+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict {
  NSString  *classString = [dict objectForKey: @"class"];
  
  if ([classString isEqualToString: @"ItemSizeTest"]) {
    return [ItemSizeTest fileItemTestFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"CompoundAndItemTest"]) {
    return [CompoundAndItemTest fileItemTestFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"CompoundOrItemTest"]) {
    return [CompoundOrItemTest fileItemTestFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"NotItemTest"]) {
    return [NotItemTest fileItemTestFromDictionary: dict];
  } 
  else if ([classString isEqualToString: @"ItemNameTest"]) {
    return [ItemNameTest fileItemTestFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"ItemPathTest"]) {
    return [ItemPathTest fileItemTestFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"ItemTypeTest"]) {
    return [ItemTypeTest fileItemTestFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"ItemFlagsTest"]) {
    return [ItemFlagsTest fileItemTestFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"SelectiveItemTest"]) {
    return [SelectiveItemTest fileItemTestFromDictionary: dict];
  }
  
  NSAssert1(NO, @"Unrecognized file item test class \"%@\".", classString);
}


- (NSDictionary *)dictionaryForObject {
  NSMutableDictionary  *dict = [NSMutableDictionary dictionaryWithCapacity: 8];
  
  [self addPropertiesToDictionary: dict];
  
  return dict;
}

@end // @implementation FileItemTest


@implementation FileItemTest (ProtectedMethods)

/* Initialiser used when the test is restored from a dictionary.
 *
 * Note: Special case. Does not call own designated initialiser. It should
 * be overridden and only called by initialisers with the same signature.
 */
- (id) initWithPropertiesFromDictionary:(NSDictionary *)dict {
  if (self = [super init]) {
    // void
  }
  
  return self;
}

- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  // void
}

@end // @implementation FileItemTest (ProtectedMethods)
