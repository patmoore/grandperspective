#import <Cocoa/Cocoa.h>

#import "Item.h"

@class FileItem;

@interface ItemInventory : NSObject {

  NSMutableDictionary  *typeForExtension;
  NSMutableSet  *untypedExtensions;
  NSMutableDictionary  *infoForFileType;
  NSMutableSet  *parentlessTypes;
}

+ (ItemInventory *)defaultItemInventory;

- (void) registerFileItem: (FileItem *)item;

// Returns the UTI for the given file, or "NULL" if there is no properly 
// defined UTI for this file (i.e. this is the case when the UTI string is
// dynamically generated).
- (NSString *)typeForFileItem: (FileItem *)item;

- (NSEnumerator *)knownTypesEnumerator;

// TODO: Expose and implement, or expose FileTypeInfo directly?
//- (NSEnumerator *)childrenOfType: (NSString *)uti;
//- (NSEnumerator *)parentsOfType: (NSString *)uti;
//- (NSString *)descriptionOfType: (NSString *)uti;

@end
