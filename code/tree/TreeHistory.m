#import "TreeHistory.h"

#import "CompoundAndItemTest.h"
#import "DirectoryItem.h"
#import "TreeBuilder.h"


static int  nextFilterId = 1;


@interface TreeHistory (PrivateMethods)

- (id) initWithVolumeTree: (DirectoryItem *)volumeTree
         fileSizeMeasure: (NSString *)fileSizeMeasure
         scanTime: (NSDate *)scanTime
         filter: (NSObject <FileItemTest> *)filter
         filterId: (int) filterId;

@end


@implementation TreeHistory

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithTree:freeSpace:fileSizeMeasure: instead.");
}


- (id) initWithVolumeTree: (DirectoryItem *)volumeTreeVal
         fileSizeMeasure: (NSString *)fileSizeMeasureVal {
  return [self initWithVolumeTree: volumeTreeVal 
                 fileSizeMeasure: fileSizeMeasureVal 
                 scanTime: [NSDate date]
                 filter: nil 
                 filterId: 0];
}

- (void) dealloc {
  [volumeTree release];
  [fileSizeMeasure release];
  [scanTime release];
  [filter release];

  [super dealloc];
}


- (TreeHistory*) historyAfterFiltering: (DirectoryItem *)newTree
                   filter: (NSObject <FileItemTest> *)newFilter {
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

  return [[[TreeHistory alloc] initWithVolumeTree: newTree
                                 fileSizeMeasure: fileSizeMeasure
                                 scanTime: scanTime
                                 filter: totalFilter
                                 filterId: nextFilterId++] autorelease];
}

- (TreeHistory*) historyAfterRescanning: (DirectoryItem *)newTree {
  return [[[TreeHistory alloc] initWithVolumeTree: newTree
                                 fileSizeMeasure: fileSizeMeasure
                                 scanTime: [NSDate date]
                                 filter: filter
                                 filterId: filterId] autorelease];
}


- (DirectoryItem*) volumeTree {
  return volumeTree;
}

- (DirectoryItem*) scanTree {
  return [TreeBuilder scanTreeOfVolume: volumeTree];
}


- (unsigned long long) freeSpace {
  return [TreeBuilder freeSpaceOfVolume: volumeTree];
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

- (id) initWithVolumeTree: (DirectoryItem *)volumeTreeVal
         fileSizeMeasure: (NSString *)fileSizeMeasureVal
         scanTime: (NSDate *)scanTimeVal
         filter: (NSObject <FileItemTest> *)filterVal
         filterId: (int) filterIdVal {
  if (self = [super init]) {
    NSAssert([volumeTreeVal parentDirectory]==nil,
                @"Tree must be the volume tree.");
    volumeTree = [volumeTreeVal retain];

    fileSizeMeasure = [fileSizeMeasureVal retain];
    scanTime = [scanTimeVal retain];

    filter = [filterVal retain];
    filterId = filterIdVal;
  }
  
  return self;
}

@end // TreeHistory (PrivateMethods)

