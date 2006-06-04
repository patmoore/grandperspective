#import <Cocoa/Cocoa.h>

#import "StringTest.h"
#import "AbstractFileItemTest.h"


/**
 * Item name test.
 */
@interface ItemNameTest : AbstractFileItemTest {

  NSObject <StringTest>*  stringTest;

}

- (id) initWithName:(NSString*)name 
         stringTest:(NSObject <StringTest>*)stringTest;

@end
