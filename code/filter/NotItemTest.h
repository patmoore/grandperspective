#import <Cocoa/Cocoa.h>

#import "AbstractFileItemTest.h"

@interface NotItemTest : AbstractFileItemTest {
  NSObject <FileItemTest>  *subItemTest;
}

- (id) initWithSubItemTest:(NSObject<FileItemTest> *)subItemTest;

- (NSObject <FileItemTest> *) subItemTest;

@end
