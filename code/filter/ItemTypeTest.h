#import <Cocoa/Cocoa.h>

#import "FileItemTest.h"


/**
 * Item type test.
 */
@interface ItemTypeTest : NSObject<FileItemTest>  {

  BOOL  testForPlainFile;

}


- (id) initWithTestForPlainFile:(BOOL)plainFileFlag;

- (BOOL) testsForPlainFile;

@end
