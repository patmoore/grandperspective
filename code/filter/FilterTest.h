#import <Cocoa/Cocoa.h>


@class FileItemTest;

@interface FilterTest : NSObject {
  NSString  *name;
  FileItemTest  *test;
}

+ (id) filterTestWithName:(NSString *)name fileItemTest:(FileItemTest *)test;

- (id) initWithName:(NSString *)name fileItemTest:(FileItemTest *)test;

- (NSString *)name;
- (FileItemTest *)fileItemTest;

@end
