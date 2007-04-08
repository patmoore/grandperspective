#import <Cocoa/Cocoa.h>


@protocol FileItemTest;
@class DirectoryItem;

@interface TreeHistory : NSObject {
  DirectoryItem  *treeRoot;

  NSDate  *scanTime;
  NSString  *fileSizeMeasure;
  unsigned long long  freeSpace;
  
  NSObject <FileItemTest>  *filter;
  int  filterId;
}

// Scan time is set to "now".
- (id) initWithTree: (DirectoryItem *)treeRoot 
         freeSpace: (unsigned long long) space
         fileSizeMeasure: (NSString *)measure;

// Scan time defaults to "now". "newFilter" is the newly applied filter,
// which does not include any filters that had already been applied earlier.
- (TreeHistory*) historyAfterFiltering: (DirectoryItem *)newTree
                   filter: (NSObject <FileItemTest> *)newFilter;

// Scan time is set to "now".
- (TreeHistory*) historyAfterRescanning: (DirectoryItem *)newTree
                   freeSpace: (unsigned long long) space;

- (DirectoryItem*) itemTree;

- (NSString*) fileSizeMeasure;
- (NSDate*) scanTime;
- (unsigned long long) freeSpace;

- (NSObject <FileItemTest>*) fileItemFilter;

// A unique identifier for the filter. Returns "0" iff there is no filter.
- (int) filterIdentifier;

// Returns a localized string, based on the filter identifier.
- (NSString*) filterName;

@end
