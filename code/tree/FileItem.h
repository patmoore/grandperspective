#import <Cocoa/Cocoa.h>

#import "Item.h"

/* Bitmasks used for the flags field of the FileItem
 */
#define FILE_IS_SPECIAL 0x01
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

/* Returns YES iff the file item is special. An item is special if it does not 
 * represent an actual file.  E.g. a special file item may represent the free 
 * space on a volume. 
 */
- (BOOL) isSpecial;

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


- (NSString*) stringForFileItemPath;

// Returns a short string, approximating the given size. E.g. "1.23 MB"
+ (NSString*) stringForFileItemSize: (ITEM_SIZE)size;

// Returns a string, specifying the file size exactly. E.g. "12345678 bytes"
+ (NSString*) exactStringForFileItemSize: (ITEM_SIZE)size;

@end
