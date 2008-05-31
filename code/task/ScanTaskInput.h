#import <Cocoa/Cocoa.h>

@protocol FileItemTest;


@interface ScanTaskInput : NSObject {
  BOOL  packagesAsFiles;
  NSString  *dirName;
  NSString  *fileSizeMeasure;
  NSObject <FileItemTest>  *filterTest;
}

- (id) initWithDirectoryName: (NSString *)name 
         fileSizeMeasure: (NSString *) measure
         filterTest: (NSObject <FileItemTest> *)filter;

- (id) initWithDirectoryName: (NSString *)name 
         fileSizeMeasure: (NSString *) measure
         filterTest: (NSObject <FileItemTest> *)filter
         packagesAsFiles: (BOOL) packagesAsFiles;

- (NSString *) directoryName;
- (NSString *) fileSizeMeasure;
- (NSObject <FileItemTest> *) filterTest;
- (BOOL) packagesAsFiles;

@end
