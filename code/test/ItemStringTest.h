#import <Cocoa/Cocoa.h>

#import "FileItemTest.h"

@class StringTest;

/**
 * (Abstract) item string-based test.
 */
@interface ItemStringTest : FileItemTest  {

  StringTest  *stringTest;

}

- (id) initWithStringTest:(StringTest *)stringTest;

- (StringTest *)stringTest;

@end
