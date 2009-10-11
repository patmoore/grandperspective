#import <Cocoa/Cocoa.h>

@class FilterSet;


@interface ScanTaskInput : NSObject {
  BOOL  packagesAsFiles;
  NSString  *pathToScan;
  NSString  *fileSizeMeasure;
  FilterSet  *filterSet;
}

- (id) initWithPath:(NSString *)path 
         fileSizeMeasure:(NSString *) measure
         filterSet:(FilterSet *)filterSet;

- (id) initWithPath:(NSString *)path 
         fileSizeMeasure:(NSString *) measure
         filterSet:(FilterSet *)filterSet
         packagesAsFiles:(BOOL) packagesAsFiles;

- (NSString *) pathToScan;
- (NSString *) fileSizeMeasure;
- (FilterSet *) filterSet;
- (BOOL) packagesAsFiles;

@end
