#import <Cocoa/Cocoa.h>

@class FileItem;

@protocol FileItemTest

- (BOOL) testFileItem:(FileItem*)item;

- (NSString*) name;
- (void) setName:(NSString*)name;

@end
