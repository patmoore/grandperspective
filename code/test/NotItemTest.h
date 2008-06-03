#import <Cocoa/Cocoa.h>

#import "AbstractFileItemTest.h"

@interface NotItemTest : AbstractFileItemTest {
  NSObject <FileItemTest>  *subTest;
}

- (id) initWithSubItemTest: (NSObject<FileItemTest> *)subTest;

- (NSObject <FileItemTest> *) subItemTest;

+ (NSObject *) objectFromDictionary: (NSDictionary *)dict;

@end
