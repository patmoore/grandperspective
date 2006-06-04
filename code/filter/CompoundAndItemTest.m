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

- (NSString*) description {
  NSMutableString  *descr = [NSMutableString stringWithCapacity:128];

  int  max = [subTests count];
  int  i = 0;
  while (i < max) {
    if (i > 0) {
      [descr appendString:@" AND "];
    }
    [descr appendString: [[subTests objectAtIndex:i++] description]];
  }
  
  return descr;
}

@end
