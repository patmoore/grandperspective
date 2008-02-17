#import <Cocoa/Cocoa.h>

#import "Item.h"

@class FileItem;
@class UniformType;


@interface UniformTypeInventory : NSObject {

  // Maps NSStrings to UniformTypes
  NSMutableDictionary  *typeForExtension;

  // Contains NSStrings
  NSMutableSet  *untypedExtensions;

  // Maps NSStrings to UniformTypes
  NSMutableDictionary  *typeForUTI;

  // Contains UniformTypes
  NSMutableSet  *parentlessTypes;
}

+ (UniformTypeInventory *)defaultUniformTypeInventory;

- (void) registerFileItem: (FileItem *)item;

// Returns the FileType object for the UTI for the given file, or "nil" if 
// there is no properly defined UTI for this file (i.e. this is the case when 
// the UTI string is dynamically generated).
- (UniformType *)uniformTypeForFileItem: (FileItem *)item;

- (UniformType *)uniformTypeForIdentifier: (NSString *)uti;

/* Enumerates over all types maintained by this inventory. These types include
 * those that have been registered directly, as well as those that have been
 * registered indirectly (as a result of being ancestors of a registered type).
 */
- (NSEnumerator *)uniformTypeEnumerator;

// For debugging.
- (void) dumpTypesToLog;

@end
