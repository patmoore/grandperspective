#import <Cocoa/Cocoa.h>

#import "Item.h"

/* Bitmasks used for the flags field of the FileItem
 */
// Note: Using "NOT_PHYSICAL" as a mask as opposed to "PHYSICAL" so that a set
// bit signals an exceptional setting. 
#define FILE_IS_NOT_PHYSICAL 0x01
#define FILE_IS_HARDLINKED 0x02
#define FILE_IS_PACKAGE 0x04


@class DirectoryItem;

@interface FileItem : Item {
  NSString  *name;
  DirectoryItem  *parent;

  // Bitmask for storing boolean properties of the file
  UInt8  flags;
}

- (id) initWithName: (NSString *)name parent: (DirectoryItem *)parent;
- (id) initWithName: (NSString *)name parent: (DirectoryItem *)parent
         flags: (UInt8) flags;
- (id) initWithName: (NSString *)name parent: (DirectoryItem *)parent 
         size: (ITEM_SIZE) size;
- (id) initWithName: (NSString *)name parent: (DirectoryItem *)parent 
         size: (ITEM_SIZE) size flags: (UInt8) flags;
         
/* Creates a duplicate item, for use in a new tree (so with a new parent).
 *
 * Note: If the item is a directory, its contents still need to be set, as
 * these can be different from the original item, e.g. by applying a filter.
 */
- (FileItem *) duplicateFileItem: (DirectoryItem *)newParent;


- (NSString *) name;

- (DirectoryItem *) parentDirectory;

- (BOOL) isAncestorOfFileItem: (FileItem *)fileItem;
  
/* Returns YES iff the file item is a directory.
 */
- (BOOL) isDirectory;


/* Bit-mask flags. Lower-level representation for the file's physical, 
 * hard-linked, and package status.
 */
- (UInt8) fileItemFlags;

/* Returns YES iff the file item is physical, i.e. it is an actual file on the
 * file system. A file item that is not physical may for example represent the
 * free space on a volume. 
 */
- (BOOL) isPhysical;

/* Returns YES iff the file item is hardlinked.
 */
- (BOOL) isHardLinked;

/* Return YES iff the file item is a package.
 *
 * Note: Although packages are always directories in the underlying file 
 * system, they may be represented by file items that are plain files 
 * (namely when package contents are hidden). This is the reason that this
 * method is introduced by the FileItem class.
 */
- (BOOL) isPackage;


/* Returns the path component that the item contributes to the path. The path
 * component is nil if the item is not physical.
 */
- (NSString *) pathComponent;

/* Returns the path to the file item. It is the path as shown to the user. The
 * system representation of the path can be different. This is for example the
 * case when a path component contain slash characters.
 */
- (NSString *) path;


/* Returns a short string, approximating the given size. E.g. "1.23 MB"
 */
+ (NSString *) stringForFileItemSize: (ITEM_SIZE)size;

/* Returns a string, specifying the file size exactly. E.g. "12345678 bytes"
 */
+ (NSString *) exactStringForFileItemSize: (ITEM_SIZE)size;

@end
