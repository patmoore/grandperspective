#import <Cocoa/Cocoa.h>


@interface ScanTaskInput : NSObject {
  NSString  *dirName;
  NSString  *fileSizeMeasure;
}

- (id) initWithDirectoryName: (NSString *)name 
         fileSizeMeasure: (NSString *) measure;

- (NSString *) directoryName;
- (NSString *) fileSizeMeasure;

@end
