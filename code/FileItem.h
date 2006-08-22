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
  
- (BOOL) isPlainFile;

- (NSString*) stringForFileItemPath;

// Returns a short string, approximating the given size. E.g. "1.23 MB"
+ (NSString*) stringForFileItemSize: (ITEM_SIZE)size;

// Returns a string, specifying the file size exactly. E.g. "12345678 bytes"
+ (NSString*) exactStringForFileItemSize: (ITEM_SIZE)size;

@end
