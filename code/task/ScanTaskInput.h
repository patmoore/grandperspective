#import <Cocoa/Cocoa.h>


@interface ScanTaskInput : NSObject {
  NSString  *dirName;
  int  fileSizeType;
}

- (id) initWithDirectoryName: (NSString *)name 
         fileSizeType: (int)fileSizeType;

- (NSString*) directoryName;

- (int) fileSizeType;

@end
