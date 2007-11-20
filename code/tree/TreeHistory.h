#import <Cocoa/Cocoa.h>


@protocol FileItemTest;
@class DirectoryItem;

@interface TreeHistory : NSObject {
  DirectoryItem  *volumeTree;

  NSDate  *scanTime;
  NSString  *fileSizeMeasure;
  
  NSObject <FileItemTest>  *filter;
  int  filterId;
}

// Scan time is set to "now".
- (id) initWithVolumeTree: (DirectoryItem *)volumeTree 
         fileSizeMeasure: (NSString *)measure;

// Scan time defaults to "now". "newFilter" is the newly applied filter,
// which does not include any filters that had already been applied earlier.
- (TreeHistory*) historyAfterFiltering: (DirectoryItem *)newTree
                   filter: (NSObject <FileItemTest> *)newFilter;

// Scan time is set to "now".
- (TreeHistory*) historyAfterRescanning: (DirectoryItem *)newTree;

- (DirectoryItem*) volumeTree;
- (DirectoryItem*) scanTree;

- (unsigned long long) freeSpace;

- (NSString*) fileSizeMeasure;
- (NSDate*) scanTime;

- (NSObject <FileItemTest>*) fileItemFilter;

// A unique identifier for the filter. Returns "0" iff there is no filter.
- (int) filterIdentifier;

// Returns a localized string, based on the filter identifier.
- (NSString*) filterName;

@end
