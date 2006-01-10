#import <Cocoa/Cocoa.h>

#import "FileItem.h"

@interface DirectoryItem : FileItem {
  Item*  contents;
}

- (void) setDirectoryContents:(Item*)contents size:(ITEM_SIZE)dirSize;

- (Item*) getContents;

@end
