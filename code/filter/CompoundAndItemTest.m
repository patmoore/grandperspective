#import "CompoundAndItemTest.h"

#import "FileItemTestVisitor.h"


@implementation CompoundAndItemTest

- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  [dict setObject: @"CompoundAndItemTest" forKey: @"class"];
}


- (BOOL) testFileItem: (FileItem *)item context: (id)context {
  int  max = [subTests count];
  int  i = 0;
  BOOL  applicable = NO;
  
  while (i < max) {
    TestResult  result = 
      [[subTests objectAtIndex: i++] testFileItem: item context: context];
      
    if (result == TEST_FAILED) {
      // Short-circuit evaluation
      return TEST_FAILED;
    }
    if (result == TEST_PASSED) {
      // Test cannot return "TEST_NOT_APPLICABLE" anymore
      applicable = YES;
    }
  }

  return ( applicable ? TEST_PASSED : TEST_NOT_APPLICABLE );
}

- (void) acceptFileItemTestVisitor: (NSObject <FileItemTestVisitor> *)visitor {
  [visitor visitCompoundAndItemTest: self];
}


- (NSString *) bootstrapDescriptionTemplate {
  return NSLocalizedStringFromTable( 
           @"(%@) and (%@)" , @"Tests", 
           @"AND-test with 1: sub test, and 2: another sub test" );
}

- (NSString *) repeatingDescriptionTemplate {
  return NSLocalizedStringFromTable( 
           @"(%@) and %@" , @"Tests", 
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
