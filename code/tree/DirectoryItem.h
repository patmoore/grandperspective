#import <Cocoa/Cocoa.h>

#import "FileItem.h"

/* Bitmasks used for the flags field of the DirectoryItem
 */
#define DIRECTORY_IS_PACKAGE 0x04


@interface DirectoryItem : FileItem {
  Item  *contents;
}


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

- (BOOL) isPackage;

@end
