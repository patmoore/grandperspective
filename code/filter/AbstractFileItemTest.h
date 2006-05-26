#import <Cocoa/Cocoa.h>

#import "FileItemTest.h"

@interface AbstractFileItemTest : NSObject<FileItemTest> {

  NSString*  name;

}

- (id) initWithName:(NSString*)name;

@end
