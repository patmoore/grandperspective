#import "ScanTaskExecutor.h"

#import "TreeBuilder.h"
#import "DirectoryItem.h"
#import "TreeContext.h"
#import "ScanTaskInput.h"
#import "FilteredTreeGuide.h"


@implementation ScanTaskExecutor

- (id) init {
  if (self = [super init]) {
    taskLock = [[NSLock init] alloc];

    enabled = YES;    
  }
  return self;
}

- (void) dealloc {
  [taskLock release];
  
  NSAssert(treeBuilder==nil, @"treeBuilder should be nil.");
  
  [super dealloc];
}


- (id) runTaskWithInput: (id) input {
  if (!enabled) {
    return nil;
  }
  
  NSAssert( treeBuilder==nil, @"treeBuilder already set.");

  ScanTaskInput  *myInput = input;
  FilteredTreeGuide  *treeGuide = 
    [[[FilteredTreeGuide alloc] 
         initWithFileItemTest: [myInput filterTest]
           packagesAsFiles: [myInput packagesAsFiles]] autorelease];

  [taskLock lock];
  treeBuilder = [[TreeBuilder alloc] initWithFilteredTreeGuide: treeGuide];
  [treeBuilder setFileSizeMeasure: [myInput fileSizeMeasure]];
  [taskLock unlock];
  
  NSDate  *startTime = [NSDate date];
  
  TreeContext*  scanResult = 
    [treeBuilder buildTreeForPath: [myInput pathToScan]];
  
  if (scanResult != nil) {
    NSLog(@"Done scanning: %d folders scanned in %.2fs.",
          [[[self scanProgressInfo] objectForKey: NumFoldersBuiltKey] intValue],
          -[startTime timeIntervalSinceNow]);
  }
  else {
    NSLog(@"Scanning aborted.");
  }

  [taskLock lock];
  [treeBuilder release];
  treeBuilder = nil;
  [taskLock unlock];

  return scanResult;
}


- (void) disable {
  enabled = NO;

  [treeBuilder abort];
}

- (void) enable {
  enabled = YES;
}

- (NSDictionary *)scanProgressInfo {
  NSDictionary  *dict;

  [taskLock lock];
  // The "taskLock" ensures that when treeBuilder is not nil, the object will
  // always be valid when it is used (i.e. it won't be deallocated).
  dict = [treeBuilder treeBuilderProgressInfo];
  [taskLock unlock];
  
  return dict;
}

@end
