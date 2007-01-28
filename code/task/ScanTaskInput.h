#import <Cocoa/Cocoa.h>


@interface ScanTaskInput : NSObject {
  NSString  *dirName;
  int  fileSizeMeasure;
}

- (id) initWithDirectoryName: (NSString *)name 
         fileSizeMeasure: (int) measure;

- (NSString*) directoryName;
- (int) fileSizeMeasure;

@end
