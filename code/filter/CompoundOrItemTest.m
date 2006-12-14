#import "CompoundOrItemTest.h"


@implementation CompoundOrItemTest

- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  [dict setObject: @"CompoundOrItemTest" forKey: @"class"];
}


- (BOOL) testFileItem: (FileItem *)item context: (id)context {
  int  max = [subTests count];
  int  i = 0;
  while (i < max) {
    if ([[subTests objectAtIndex: i++] testFileItem: item context: context]) {
      // Short-circuit evaluation.
      return YES;
    }
  }

  return NO;
}


- (NSString*) bootstrapDescriptionTemplate {
  return NSLocalizedStringFromTable( 
           @"(%@) or (%@)" , @"tests", 
           @"OR-test with 1: sub test, and 2: another sub test" );
}

- (NSString*) repeatingDescriptionTemplate {
  return NSLocalizedStringFromTable( 
           @"(%@) or %@" , @"tests", 
           @"OR-test with 1: sub test, and 2: two or more other sub tests" );
}


+ (NSObject *) objectFromDictionary: (NSDictionary *)dict {
  NSAssert([[dict objectForKey: @"class"] 
             isEqualToString: @"CompoundOrItemTest"],
             @"Incorrect value for class in dictionary.");

  return [[[CompoundOrItemTest alloc] initWithPropertiesFromDictionary: dict]
           autorelease];
}

@end
