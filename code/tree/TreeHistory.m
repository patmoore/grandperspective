#import "TreeHistory.h"


#import "CompoundAndItemTest.h"


@interface TreeHistory (PrivateMethods)

- (id) initWithScanTime: (NSDate *)scanTimeVal 
         filter: (NSObject <FileItemTest> *)filter;

@end


@implementation TreeHistory

// Overrides designated initialiser
- (id) init {
  return [self initWithScanTime:[NSDate date]];
}

- (id) initWithScanTime: (NSDate *)scanTimeVal {
  return [self initWithScanTime:scanTimeVal filter:nil];
}

- (void) dealloc {
  [scanTime release];
  [filter release];

  [super dealloc];
}


- (TreeHistory*) historyAfterFiltering: (NSObject <FileItemTest> *)newFilter {
  NSObject <FileItemTest>  *totalFilter = nil;
  if (filter == nil) {
    totalFilter = newFilter;
  }
  else {
    totalFilter = 
      [[[CompoundAndItemTest alloc] initWithSubItemTests:
           [NSArray arrayWithObjects:filter, newFilter, nil]] autorelease];
  }

  return [[TreeHistory alloc] initWithScanTime:scanTime filter:totalFilter];
}


- (NSDate*) scanTime {
  return scanTime;
}

- (NSObject <FileItemTest>*) fileItemFilter {
  return filter;
}

@end // TreeHistory


@implementation TreeHistory (PrivateMethods)

- (id) initWithScanTime: (NSDate *)scanTimeVal
         filter: (NSObject <FileItemTest> *)filterVal {
  if (self = [super init]) {
    scanTime = [scanTimeVal retain];
    filter = [filterVal retain];
  }
  
  return self;
}

@end // TreeHistory (PrivateMethods)

