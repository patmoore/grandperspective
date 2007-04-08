#import "ScanTaskExecutor.h"

#import "TreeBuilder.h"
#import "DirectoryItem.h"
#import "TreeHistory.h"
#import "ScanTaskInput.h"


@implementation ScanTaskExecutor

- (id) init {
  if (self = [super init]) {
    enabled = YES;
  }
  return self;
}

- (void) dealloc {
  [treeBuilder release];
  
  [super dealloc];
}


- (id) runTaskWithInput: (id) input {
  if (!enabled) {
    return nil;
  }
  
  ScanTaskInput  *myInput = input;
  
  NSAssert( treeBuilder==nil, @"treeBuilder already set.");
  treeBuilder = [[TreeBuilder alloc] init];
  [treeBuilder setFileSizeMeasure: [myInput fileSizeMeasure]];
  
  NSDate  *startTime = [NSDate date];
  
  DirectoryItem*  itemTree = 
    [treeBuilder buildTreeForPath: [myInput directoryName]];
  
  [treeBuilder release];
  treeBuilder = nil;
  
  if (itemTree == nil) {
    // Scanning was aborted.
    return nil;
  }
  
  // Establish the free space (at time of scan)  
  NSFileManager  *manager = [NSFileManager defaultManager];
  NSDictionary  *fsattrs = 
    [manager fileSystemAttributesAtPath: [myInput directoryName]];
  unsigned long long  freeSpace = 
    [[fsattrs objectForKey: NSFileSystemFreeSize] unsignedLongLongValue];

  NSLog(@"Done scanning. Total size=%qu, Free space=%qu, Time taken=%f", 
          [itemTree itemSize], freeSpace, -[startTime timeIntervalSinceNow]);
  
  return [[[TreeHistory alloc] 
              initWithTree: itemTree freeSpace: freeSpace
              fileSizeMeasure: [myInput fileSizeMeasure]] autorelease];
}


- (void) disable {
  enabled = NO;

  [treeBuilder abort];
}


- (void) enable {
  enabled = YES;
}

@end
