#import <Cocoa/Cocoa.h>

@protocol FileItemTest;


@interface ScanTaskInput : NSObject {
  NSString  *dirName;
  NSString  *fileSizeMeasure;
  NSObject <FileItemTest>  *filterTest;
}

- (id) initWithDirectoryName: (NSString *)name 
         fileSizeMeasure: (NSString *) measure
         filterTest: (NSObject <FileItemTest> *)filter;

- (NSString *) directoryName;
- (NSString *) fileSizeMeasure;
- (NSObject <FileItemTest> *) filterTest;

@end
