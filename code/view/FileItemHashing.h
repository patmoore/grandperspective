#import <Cocoa/Cocoa.h>

@class FileItem;

@interface FileItemHashing : NSObject {
}

- (int) hashForFileItem:(FileItem*)item depth:(int)depth;

@end
