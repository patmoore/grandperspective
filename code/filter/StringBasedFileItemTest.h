#import <Cocoa/Cocoa.h>

#import "StringTest.h"
#import "AbstractFileItemTest.h"


/**
 * (Abstract) string-based file item test.
 */
@interface StringBasedFileItemTest : AbstractFileItemTest {

  NSObject <StringTest>*  stringTest;

}

- (id) initWithName:(NSString*)name 
         stringTest:(NSObject <StringTest>*)stringTest;

@end
