#import <Cocoa/Cocoa.h>

#import "ItemStringTest.h"


/**
 * Item name test.
 */
@interface ItemNameTest : ItemStringTest {
}

+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict;

@end
