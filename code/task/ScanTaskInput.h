#import <Cocoa/Cocoa.h>


@interface ScanTaskInput : NSObject {
  NSString  *dirName;
  NSString  *fileSizeType;
}

- (id) initWithDirectoryName: (NSString *)name 
         fileSizeType: (NSString *)type;

- (NSString*) directoryName;

- (NSString*) fileSizeType;

@end
