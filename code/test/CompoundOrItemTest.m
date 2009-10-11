#import "CompoundOrItemTest.h"

#import "FileItemTestVisitor.h"


@implementation CompoundOrItemTest

- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  [dict setObject: @"CompoundOrItemTest" forKey: @"class"];
}


- (BOOL) testFileItem:(FileItem *)item context:(id) context {
  int  max = [subTests count];
  int  i = 0;
  BOOL  applicable = NO;
  
  while (i < max) {
    TestResult  result = 
      [[subTests objectAtIndex: i++] testFileItem: item context: context];
      
    if (result == TEST_PASSED) {
      // Short-circuit evaluation.
      return TEST_PASSED;
    }
    if (result == TEST_FAILED) {
      // Test cannot return "TEST_NOT_APPLICABLE" anymore
      applicable = YES;
    }
  }

  return ( applicable ? TEST_FAILED : TEST_NOT_APPLICABLE );
}

- (void) acceptFileItemTestVisitor:(NSObject <FileItemTestVisitor> *)visitor {
  [visitor visitCompoundOrItemTest: self];
}


- (NSString *)bootstrapDescriptionTemplate {
  return NSLocalizedStringFromTable( 
           @"(%@) or (%@)" , @"Tests", 
           @"OR-test with 1: sub test, and 2: another sub test" );
}

- (NSString *)repeatingDescriptionTemplate {
  return NSLocalizedStringFromTable( 
           @"(%@) or %@" , @"Tests", 
           @"OR-test with 1: sub test, and 2: two or more other sub tests" );
}


+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict {
  NSAssert([[dict objectForKey: @"class"] 
             isEqualToString: @"CompoundOrItemTest"],
             @"Incorrect value for class in dictionary.");

  return [[[CompoundOrItemTest alloc] initWithPropertiesFromDictionary: dict]
              autorelease];
}

@end
