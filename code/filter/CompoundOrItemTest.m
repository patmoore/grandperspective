#import "CompoundOrItemTest.h"


@implementation CompoundOrItemTest

- (BOOL) testFileItem:(FileItem*)item {
  int  max = [subTests count];
  int  i = 0;
  while (i < max) {
    if ([[subTests objectAtIndex:i++] testFileItem:item]) {
      // Short-circuit evaluation.
      return YES;
    }
  }

  return NO;
}

- (NSString*) descriptionTemplate {
  return NSLocalizedStringFromTable( 
           @"(%@) or %@" , @"tests", 
           @"OR-test with 1: sub test, and 2: other sub tests" );
}

@end
