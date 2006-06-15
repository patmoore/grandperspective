#import <Cocoa/Cocoa.h>

#import "FileItemTest.h"


/**
 * (Abstract) compound item test.
 */
@interface CompoundItemTest : NSObject<FileItemTest>  {
  NSArray  *subTests;
}

- (id) initWithSubItemTests:(NSArray*)subTests;

- (NSArray*) subItemTests;

@end
