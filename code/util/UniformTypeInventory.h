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

  // The generic "unknown" type.
  UniformType  *unknownType;

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

- (unsigned) count;

- (NSSet *)childrenOfUniformType: (UniformType *)type;

/* Returns the type associated with the given file extension. If there is no
 * properly defined type, it returns the type the generic "unknown" type
 * (see -unknownUniformType).
 */
- (UniformType *)uniformTypeForExtension: (NSString *)ext;

/* Returns the type that corresponds to the given UTI. If the UTI is not
 * recognized, it returns "nil".
 */
- (UniformType *)uniformTypeForIdentifier: (NSString *)uti;

/* Enumerates over all types maintained by this inventory. These types include
 * those that have been registered directly, as well as those that have been
 * registered indirectly (as a result of being ancestors of a registered type).
 */
- (NSEnumerator *)uniformTypeEnumerator;

/* Returns the generic unknown type. It can be used whenever there is no proper
 * uniform type for a given file, extension or UTI.
 */
- (UniformType *)unknownUniformType;

// For debugging.
- (void) dumpTypesToLog;

@end
