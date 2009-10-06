#import <Cocoa/Cocoa.h>

@class FileItemFilterSet;


@interface ScanTaskInput : NSObject {
  BOOL  packagesAsFiles;
  NSString  *pathToScan;
  NSString  *fileSizeMeasure;
  FileItemFilterSet  *filterSet;
}

- (id) initWithPath:(NSString *)path 
         fileSizeMeasure:(NSString *) measure
         filterSet:(FileItemFilterSet *)filterSet;

- (id) initWithPath:(NSString *)path 
         fileSizeMeasure:(NSString *) measure
         filterSet:(FileItemFilterSet *)filterSet
         packagesAsFiles:(BOOL) packagesAsFiles;

- (NSString *) pathToScan;
- (NSString *) fileSizeMeasure;
- (FileItemFilterSet *) filterSet;
- (BOOL) packagesAsFiles;

@end
