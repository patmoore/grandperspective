#import "TreeHistory.h"


#import "CompoundAndItemTest.h"


static int  nextFilterId = 1;


@interface TreeHistory (PrivateMethods)

- (id) initWithFileSizeMeasure: (NSString *)measure
         scanTime: (NSDate *)time 
         filter: (NSObject <FileItemTest> *)filter
         filterId: (int) id;

@end


@implementation TreeHistory

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithFileSizeType: instead.");
}

- (id) initWithFileSizeMeasure: (NSString *)measure {
  return [self initWithFileSizeMeasure: measure scanTime: [NSDate date]];
}

- (id) initWithFileSizeMeasure: (NSString *)measure 
         scanTime: (NSDate *)time {
  return [self initWithFileSizeMeasure: measure scanTime: time 
                 filter: nil filterId: 0];
}

- (void) dealloc {
  [fileSizeMeasure release];
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

  return [[[TreeHistory alloc] initWithFileSizeMeasure: fileSizeMeasure
                                 scanTime: scanTime 
                                 filter: totalFilter
                                 filterId: nextFilterId++] autorelease];
}


- (TreeHistory*) historyAfterRescanning {
  return [self historyAfterRescanning: [NSDate date]];
}

- (TreeHistory*) historyAfterRescanning: (NSDate *)scanTimeVal {
  return [[[TreeHistory alloc] initWithFileSizeMeasure: fileSizeMeasure
                                 scanTime: scanTimeVal 
                                 filter: filter
                                 filterId: filterId] autorelease];
}


- (NSString*) fileSizeMeasure {
  return fileSizeMeasure;
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

- (NSString*) filterName {
  if (filterId == 0) {
    // There is no filter
    return NSLocalizedString( @"None", 
                              @"The filter name when there is no filter." );
  }
  else {
    NSString  *format = NSLocalizedString( @"Filter%d", 
                                           @"Filter naming template." );
    return [NSString stringWithFormat: format, filterId];
  }
}

@end // TreeHistory


@implementation TreeHistory (PrivateMethods)

- (id) initWithFileSizeMeasure: (NSString *)fileSizeMeasureVal
         scanTime: (NSDate *)scanTimeVal
         filter: (NSObject <FileItemTest> *)filterVal 
         filterId: (int) filterIdVal {
  if (self = [super init]) {
    fileSizeMeasure = [fileSizeMeasureVal retain];
    scanTime = [scanTimeVal retain];
    filter = [filterVal retain];
    filterId = filterIdVal;
  }
  
  return self;
}

@end // TreeHistory (PrivateMethods)

