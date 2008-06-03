#import <Cocoa/Cocoa.h>

#import "AbstractFileItemTest.h"

@protocol StringTest;

/**
 * (Abstract) item string-based test.
 */
@interface ItemStringTest : AbstractFileItemTest  {

  NSObject <StringTest>*  stringTest;

}

- (id) initWithStringTest:(NSObject <StringTest>*)stringTest;

- (NSObject <StringTest>*) stringTest;

@end
