#import "TreeHistory.h"


#import "CompoundAndItemTest.h"


static int  nextFilterId = 1;


@interface TreeHistory (PrivateMethods)

- (id) initWithFileSizeType: (NSString *)fileSizeTypeVal
         scanTime: (NSDate *)scanTimeVal 
         filter: (NSObject <FileItemTest> *)filter
         filterId: (int) filterId;

@end


@implementation TreeHistory

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithFileSizeType: instead.");
}

- (id) initWithFileSizeType: (NSString *)fileSizeTypeVal {
  return [self initWithFileSizeType: fileSizeTypeVal scanTime: [NSDate date]];
}

- (id) initWithFileSizeType: (NSString *)fileSizeTypeVal 
         scanTime: (NSDate *)scanTimeVal {
  return [self initWithFileSizeType: fileSizeTypeVal scanTime: scanTimeVal 
                 filter: nil filterId: 0];
}

- (void) dealloc {
  [fileSizeType release];
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

  return [[[TreeHistory alloc] initWithFileSizeType: fileSizeType
                                 scanTime: scanTime 
                                 filter: totalFilter
                                 filterId: nextFilterId++] autorelease];
}


- (TreeHistory*) historyAfterRescanning {
  return [self historyAfterRescanning: [NSDate date]];
}

- (TreeHistory*) historyAfterRescanning: (NSDate *)scanTimeVal {
  return [[[TreeHistory alloc] initWithFileSizeType: fileSizeType
                                 scanTime: scanTimeVal 
                                 filter: filter
                                 filterId: filterId] autorelease];
}


- (NSString*) fileSizeType {
  return fileSizeType;
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

- (id) initWithFileSizeType: (NSString *)fileSizeTypeVal
         scanTime: (NSDate *)scanTimeVal
         filter: (NSObject <FileItemTest> *)filterVal 
         filterId: (int) filterIdVal {
  if (self = [super init]) {
    fileSizeType = [fileSizeTypeVal retain];
    scanTime = [scanTimeVal retain];
    filter = [filterVal retain];
    filterId = filterIdVal;
  }
  
  return self;
}

@end // TreeHistory (PrivateMethods)

