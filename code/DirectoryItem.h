#import <Cocoa/Cocoa.h>

#import "FileItem.h"

@interface DirectoryItem : FileItem {
  Item  *contents;
}

+ (DirectoryItem*) specialDirectoryItemWithName:(NSString *)name
                     parent:(DirectoryItem *)parent;

- (void) setDirectoryContents:(Item *)contents;

- (Item*) getContents;

@end
