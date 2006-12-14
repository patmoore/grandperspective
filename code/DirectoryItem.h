#import <Cocoa/Cocoa.h>

#import "FileItem.h"

@interface DirectoryItem : FileItem {
  Item  *contents;
  NSString  *fileItemPathStringCache;
}

- (void) setDirectoryContents:(Item*)contents size:(ITEM_SIZE)dirSize;

- (Item*) getContents;

- (void) clearFileItemPathStringCache;

@end
