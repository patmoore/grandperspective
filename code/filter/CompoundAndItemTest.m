#import "CompoundAndItemTest.h"


@implementation CompoundAndItemTest

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

- (NSString*) descriptionTemplate {
  return NSLocalizedStringFromTable( 
           @"(%@) and %@" , @"tests", 
           @"AND-test with 1: sub test, and 2: other sub tests" );
}

@end
