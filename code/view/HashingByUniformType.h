#import <Cocoa/Cocoa.h>

#import "FileItemHashing.h"


@interface HashingByUniformType : FileItemHashing {

  // Cache mapping UTIs (NSString) to integer values (NSNumber)
  NSMutableDictionary  *hashForUTICache;
  
  NSArray  *orderedTypes;
}

@end
