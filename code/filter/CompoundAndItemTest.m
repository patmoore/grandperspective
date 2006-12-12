#import "CompoundAndItemTest.h"


@implementation CompoundAndItemTest

- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  [dict setObject: @"CompoundAndItemTest" forKey: @"class"];
}


- (BOOL) testFileItem:(FileItem*)item {
  int  max = [subTests count];
  int  i = 0;
  while (i < max) {
    if (! [[subTests objectAtIndex:i++] testFileItem:item]) {
      // Short-circuit evaluation.
      return NO;
    }
  }

  return YES;
}


- (NSString*) bootstrapDescriptionTemplate {
  return NSLocalizedStringFromTable( 
           @"(%@) and (%@)" , @"tests", 
           @"AND-test with 1: sub test, and 2: another sub test" );
}

- (NSString*) repeatingDescriptionTemplate {
  return NSLocalizedStringFromTable( 
           @"(%@) and %@" , @"tests", 
           @"AND-test with 1: sub test, and 2: two or more other sub tests" );
}


+ (NSObject *) objectFromDictionary: (NSDictionary *)dict {
  NSAssert([[dict objectForKey: @"class"] 
             isEqualToString: @"CompoundAndItemTest"],
             @"Incorrect value for class in dictionary.");

  return [[[CompoundAndItemTest alloc] initWithPropertiesFromDictionary: dict]
           autorelease];
}

@end
