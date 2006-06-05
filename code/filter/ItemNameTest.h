#import <Cocoa/Cocoa.h>

#import "StringTest.h"
#import "FileItemTest.h"


/**
 * Item name test.
 */
@interface ItemNameTest : NSObject<FileItemTest>  {

  NSObject <StringTest>*  stringTest;

}

- (id) initWithStringTest:(NSObject <StringTest>*)stringTest;

- (NSObject <StringTest>*) stringTest;

@end
