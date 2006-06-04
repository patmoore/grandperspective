#import <Cocoa/Cocoa.h>

#import "AbstractFileItemTest.h"


/**
 * (Abstract) compound item test.
 */
@interface CompoundItemTest : AbstractFileItemTest {
  NSArray  *subTests;
}

- (id) initWithName:(NSString*)name subItemTests:(NSArray*)subTests;

- (NSArray*) subItemTests;

@end
