#import <Cocoa/Cocoa.h>

@protocol FileItemTest;


@interface ScanTaskInput : NSObject {
  BOOL  packagesAsFiles;
  NSString  *pathToScan;
  NSString  *fileSizeMeasure;
  NSObject <FileItemTest>  *filterTest;
}

- (id) initWithPath: (NSString *)path 
         fileSizeMeasure: (NSString *) measure
         filterTest: (NSObject <FileItemTest> *)filter;

- (id) initWithPath: (NSString *)path 
         fileSizeMeasure: (NSString *) measure
         filterTest: (NSObject <FileItemTest> *)filter
         packagesAsFiles: (BOOL) packagesAsFiles;

- (NSString *) pathToScan;
- (NSString *) fileSizeMeasure;
- (NSObject <FileItemTest> *) filterTest;
- (BOOL) packagesAsFiles;

@end
