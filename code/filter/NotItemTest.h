#import <Cocoa/Cocoa.h>

#import "FileItemTest.h"

@interface NotItemTest : NSObject<FileItemTest> {
  NSObject<FileItemTest>  *subItemTest;
}

- (id) initWithSubItemTest:(NSObject<FileItemTest> *)subItemTest;

@end
