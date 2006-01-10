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

@end
