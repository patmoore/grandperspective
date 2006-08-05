#import <Cocoa/Cocoa.h>


@protocol FileItemTest;


@interface TreeHistory : NSObject {
  NSDate  *scanTime;
  NSObject <FileItemTest>  *filter;
}

- (id) init;
- (id) initWithScanTime: (NSDate *)scanTimeVal;

- (TreeHistory*) historyAfterFiltering: (NSObject <FileItemTest> *)filter;

- (NSDate*) scanTime;
- (NSObject <FileItemTest>*) fileItemFilter;

@end
