#import <Cocoa/Cocoa.h>

#import "FileItemTest.h"

@protocol StringTest;

/**
 * (Abstract) item string-based test.
 */
@interface ItemStringTest : NSObject<FileItemTest>  {

  NSObject <StringTest>*  stringTest;

}

- (id) initWithStringTest:(NSObject <StringTest>*)stringTest;

- (NSObject <StringTest>*) stringTest;

@end
