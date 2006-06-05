#import <Cocoa/Cocoa.h>

#import "AbstractFileItemTest.h"


/**
 * (Abstract) compound item test.
 */
@interface CompoundItemTest : AbstractFileItemTest {
  NSArray  *subTests;
}

- (id) initWithSubItemTests:(NSArray*)subTests;

- (NSArray*) subItemTests;

@end
