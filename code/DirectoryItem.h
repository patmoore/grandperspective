#import <Cocoa/Cocoa.h>

#import "FileItem.h"

@interface DirectoryItem : FileItem {
  Item  *contents;
}

+ (DirectoryItem*) specialDirectoryItemWithName:(NSString *)name
                     parent:(DirectoryItem *)parent;

- (void) setDirectoryContents: (Item *)contents;

/* Replaces the directory contents. The item must have the same size as the 
 * original item (otherwise the resulting tree would be incorrect). 
 *
 * Note: It is the responsibility of the sender to ensure that this method is
 * only called when the tree can be modified (e.g. it should not be traversed
 * in another thread). Furthermore, the sender is responsible for notifying 
 * objects affected by the change.
 */
- (void) replaceDirectoryContents: (Item *)contents;

- (Item*) getContents;

@end
