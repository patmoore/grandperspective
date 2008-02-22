#import <Cocoa/Cocoa.h>


extern NSString  *UniformTypeAddedEvent;
extern NSString  *UniformTypeKey;


@class FileItem;
@class UniformType;

/* Maintains a collection of uniform types, dynamically extended with 
 * additional types when files of a new type are encountered. It maintains
 * various look-up tables to speed-up the mapping from a file to the 
 * associated uniform type.
 *
 * Note: The implementation of this class is not thread-safe. However, it has
 * been implemented so that it can be used in a background thread (in 
 * particular, it ensures that notifications are always posted from the main 
 * thread).
 */
@interface UniformTypeInventory : NSObject {

  // Maps NSStrings to UniformTypes
  NSMutableDictionary  *typeForExtension;

  // Contains NSStrings
  NSMutableSet  *untypedExtensions;

  // Maps NSStrings to UniformTypes
  NSMutableDictionary  *typeForUTI;

  // Contains UniformTypes
  NSMutableSet  *parentlessTypes;
  
  // Maps each UTI (NSString) to a list of known child types (NSArray of
  // UniformType)
  NSMutableDictionary  *childrenForUTI;
}

+ (UniformTypeInventory *)defaultUniformTypeInventory;

// Returns the FileType object for the UTI for the given file extension, or 
// "nil" if there is no properly defined UTI for this extension.
- (UniformType *)uniformTypeForExtension: (NSString *)ext;

- (UniformType *)uniformTypeForIdentifier: (NSString *)uti;

- (NSSet *)childrenOfUniformType: (UniformType *)type;

/* Enumerates over all types maintained by this inventory. These types include
 * those that have been registered directly, as well as those that have been
 * registered indirectly (as a result of being ancestors of a registered type).
 */
- (NSEnumerator *)uniformTypeEnumerator;

// For debugging.
- (void) dumpTypesToLog;

@end
