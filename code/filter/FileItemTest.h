#import <Cocoa/Cocoa.h>

#import "FileItem.h"

@protocol FileItemTest

- (BOOL) testFileItem:(FileItem*)item;

- (NSString*) name;

@end
