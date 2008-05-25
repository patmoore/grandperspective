#import <Cocoa/Cocoa.h>

#import "AbstractFileItemTest.h"


@interface ItemFlagsTest : AbstractFileItemTest {

  UInt8  flagsMask;
  UInt8  desiredResult;

}

- (id) initWithFlagsMask: (UInt8) mask desiredResult: (UInt8) result;

- (UInt8) flagsMask;
- (UInt8) desiredResult;

+ (NSObject *) objectFromDictionary: (NSDictionary *)dict;

@end
