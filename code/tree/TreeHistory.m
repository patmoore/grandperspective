#import "TreeHistory.h"


#import "CompoundAndItemTest.h"


static int  nextFilterId = 1;


@interface TreeHistory (PrivateMethods)

- (id) initWithScanTime: (NSDate *)scanTimeVal 
         filter: (NSObject <FileItemTest> *)filter
         filterId: (int) filterId;

@end


@implementation TreeHistory

// Overrides designated initialiser
- (id) init {
  return [self initWithScanTime:[NSDate date]];
}

- (id) initWithScanTime: (NSDate *)scanTimeVal {
  return [self initWithScanTime: scanTimeVal filter: nil filterId: 0];
}

- (void) dealloc {
  [scanTime release];
  [filter release];

  [super dealloc];
}


- (TreeHistory*) historyAfterFiltering: (NSObject <FileItemTest> *)newFilter {
  NSAssert(newFilter!=nil, @"Filter should not be nil.");

  NSObject <FileItemTest>  *totalFilter = nil;
  if (filter == nil) {
    totalFilter = newFilter;
  }
  else {
    totalFilter = 
      [[[CompoundAndItemTest alloc] initWithSubItemTests:
           [NSArray arrayWithObjects:filter, newFilter, nil]] autorelease];
  }

  return [[[TreeHistory alloc] initWithScanTime: scanTime 
                                 filter: totalFilter
                                 filterId: nextFilterId++] autorelease];
}


- (TreeHistory*) historyAfterRescanning {
  return [self historyAfterRescanning: [NSDate date]];
}

- (TreeHistory*) historyAfterRescanning: (NSDate *)scanTimeVal {
  return [[[TreeHistory alloc] initWithScanTime: scanTimeVal 
                                 filter: filter
                                 filterId: filterId] autorelease];
}


- (NSDate*) scanTime {
  return scanTime;
}

- (NSObject <FileItemTest>*) fileItemFilter {
  return filter;
}

- (int) filterIdentifier {
  return filterId;
}

@end // TreeHistory


@implementation TreeHistory (PrivateMethods)

- (id) initWithScanTime: (NSDate *)scanTimeVal
         filter: (NSObject <FileItemTest> *)filterVal 
         filterId: (int) filterIdVal {
  if (self = [super init]) {
    scanTime = [scanTimeVal retain];
    filter = [filterVal retain];
    filterId = filterIdVal;
  }
  
  return self;
}

@end // TreeHistory (PrivateMethods)

