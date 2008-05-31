#import <Cocoa/Cocoa.h>

@class FileItem;

@protocol TreeTraverser

- (BOOL) shouldDescendIntoFileItem: (FileItem *)item;
- (FileItem *) descendIntoFileItem: (FileItem *)item;
- (void) emergedFromFileItem: (FileItem *)item;

@end
