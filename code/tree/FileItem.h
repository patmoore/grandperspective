#import <Cocoa/Cocoa.h>

#import "Item.h"

@class DirectoryItem;

@interface FileItem : Item {
  NSString  *name;
  DirectoryItem  *parent;
}

- (NSString*) name;

- (DirectoryItem*) parentDirectory;

- (id) initWithName:(NSString*)name parent:(DirectoryItem*)parent;
- (id) initWithName:(NSString*)name parent:(DirectoryItem*)parent 
         size:(ITEM_SIZE)size;

/* Creates a duplicate item, for use in a new tree (so with a new parent).
 *
 * Note: If the item is a directory, its contents still need to be set, as
 * these can be different from the original item, e.g. by applying a filter.
 */
- (FileItem *) duplicateFileItem: (DirectoryItem *)newParent;

+ (FileItem *) specialFileItemWithName:(NSString *)name
                 parent:(DirectoryItem *)parent 
                 size:(ITEM_SIZE) size;
  
// Returns YES iff the file item is not a directory.
- (BOOL) isPlainFile;

// An item is special if it does not represent an actual file.
// E.g. a special file item may represent the free space on a volume. 
- (BOOL) isSpecial;

- (NSString*) stringForFileItemPath;

// Returns a short string, approximating the given size. E.g. "1.23 MB"
+ (NSString*) stringForFileItemSize: (ITEM_SIZE)size;

// Returns a string, specifying the file size exactly. E.g. "12345678 bytes"
+ (NSString*) exactStringForFileItemSize: (ITEM_SIZE)size;

@end
