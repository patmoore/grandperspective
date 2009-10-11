#import <Cocoa/Cocoa.h>

#import "FileItemTest.h"


@interface NotItemTest : FileItemTest {
  FileItemTest  *subTest;
}

- (id) initWithSubItemTest:(FileItemTest *)subTest;

- (FileItemTest *)subItemTest;

+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict;

@end
