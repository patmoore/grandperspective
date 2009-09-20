#import "ScanTaskExecutor.h"

#import "TreeBuilder.h"
#import "AnnotatedTreeContext.h"
#import "ScanTaskInput.h"
#import "FilteredTreeGuide.h"
#import "ProgressTracker.h"


@implementation ScanTaskExecutor

- (id) init {
  if (self = [super init]) {
    taskLock = [[NSLock alloc] init];
    treeBuilder = nil;
  }
  return self;
}

- (void) dealloc {
  [taskLock release];
  
  NSAssert(treeBuilder==nil, @"treeBuilder should be nil.");
  
  [super dealloc];
}


- (void) prepareToRunTask {
  // Can be ignored because a one-shot object is used for running the task.
}

- (id) runTaskWithInput: (id) input {
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
    NSLog(@"Done scanning: %d folders scanned (%d skipped) in %.2fs.",
            [[[self progressInfo] 
                 objectForKey: NumFoldersProcessedKey] intValue],
            [[[self progressInfo] 
                 objectForKey: NumFoldersSkippedKey] intValue],
            -[startTime timeIntervalSinceNow]);
  }
  else {
    NSLog(@"Scanning aborted.");
  }
  
  [taskLock lock];
  [treeBuilder release];
  treeBuilder = nil;
  [taskLock unlock];

  return [AnnotatedTreeContext annotatedTreeContext: scanResult];  
}

- (void) abortTask {
  [treeBuilder abort];
}


- (NSDictionary *)progressInfo {
  NSDictionary  *dict;

  [taskLock lock];
  // The "taskLock" ensures that when treeBuilder is not nil, the object will
  // always be valid when it is used (i.e. it won't be deallocated).
  dict = [treeBuilder progressInfo];
  [taskLock unlock];
  
  return dict;
}

@end
