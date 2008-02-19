#import <Cocoa/Cocoa.h>

#import "FileItemHashing.h"

extern NSString  *UniformTypesOrderingKey;


@class UniformTypeInventory;

@interface HashingByUniformType : FileItemHashing {

  // Cache mapping UTIs (NSString) to integer values (NSNumber)
  NSMutableDictionary  *hashForUTICache;
  
  // Number of changes to the UTI list in the preferences initiated by this
  // object.
  int                  pendingOwnChanges;
  
  UniformTypeInventory  *typeInventory;
  
  NSArray  *orderedUTIs;
  NSMutableSet  *unorderedUTIs;
}

@end
