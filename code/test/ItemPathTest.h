#import <Cocoa/Cocoa.h>

#import "ItemStringTest.h"


/**
 * Item path test.
 *
 * Note: The test applies to the path of the directory where the file item is
 * stored. It does not include the name of the file item itself. This way, it
 * nicely complements the ItemNameTest. 
 */
@interface ItemPathTest : ItemStringTest {
}

+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict;

@end
