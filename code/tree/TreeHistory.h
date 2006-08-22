#import <Cocoa/Cocoa.h>


@protocol FileItemTest;


@interface TreeHistory : NSObject {
  NSDate  *scanTime;
  NSObject <FileItemTest>  *filter;
  int  filterId;
}

// Scan time defaults to "now".
- (id) init;
- (id) initWithScanTime: (NSDate *)scanTimeVal;

- (TreeHistory*) historyAfterFiltering: (NSObject <FileItemTest> *)filter;

// Scan time defaults to "now".
- (TreeHistory*) historyAfterRescanning;
- (TreeHistory*) historyAfterRescanning: (NSDate *)scanTimeVal;

- (NSDate*) scanTime;
- (NSObject <FileItemTest>*) fileItemFilter;

// A unique identifier for the filter. Returns "0" iff there is no filter.
- (int) filterIdentifier;

// Returns a localised string, based on the filter identifier.
- (NSString*) filterName;

@end
