#import <Cocoa/Cocoa.h>

#import "AbstractFileItemTest.h"


/**
 * Item type test.
 */
@interface ItemTypeTest : AbstractFileItemTest {

  BOOL  testForPlainFile;

}

- (id) initWithName:(NSString*)name testForPlainFile:(BOOL)plainFileFlag;

@end
