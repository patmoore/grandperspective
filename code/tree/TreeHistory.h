#import <Cocoa/Cocoa.h>


@protocol FileItemTest;


@interface TreeHistory : NSObject {
  NSDate  *scanTime;
  NSString  *fileSizeMeasure;
  NSObject <FileItemTest>  *filter;
  int  filterId;
}

// Scan time defaults to "now".
- (id) initWithFileSizeMeasure: (NSString *)measure;
- (id) initWithFileSizeMeasure: (NSString *)measure scanTime: (NSDate *)time;

- (TreeHistory*) historyAfterFiltering: (NSObject <FileItemTest> *)filter;

// Scan time defaults to "now".
- (TreeHistory*) historyAfterRescanning;
- (TreeHistory*) historyAfterRescanning: (NSDate *)scanTimeVal;

- (NSString*) fileSizeMeasure;
- (NSDate*) scanTime;
- (NSObject <FileItemTest>*) fileItemFilter;

// A unique identifier for the filter. Returns "0" iff there is no filter.
- (int) filterIdentifier;

// Returns a localized string, based on the filter identifier.
- (NSString*) filterName;

@end
