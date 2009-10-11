#import <Cocoa/Cocoa.h>

#import "FileItemTest.h"


@interface ItemFlagsTest : FileItemTest {

  UInt8  flagsMask;
  UInt8  desiredResult;

}

- (id) initWithFlagsMask:(UInt8) mask desiredResult:(UInt8) result;

- (UInt8) flagsMask;
- (UInt8) desiredResult;

+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict;

@end
