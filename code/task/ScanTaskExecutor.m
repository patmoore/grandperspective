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
  NSString  *path = [myInput directoryName];
  
  NSAssert( treeBuilder==nil, @"treeBuilder already set.");
  treeBuilder = [[TreeBuilder alloc] init];
  [treeBuilder setFileSizeMeasure: [myInput fileSizeMeasure]];
  
  NSDate  *startTime = [NSDate date];
  
  DirectoryItem*  volumeTree = [treeBuilder buildVolumeTreeForPath: path];
  
  [treeBuilder release];
  treeBuilder = nil;
  
  if (volumeTree == nil) {
    // Scanning was aborted.
    return nil;
  }

  NSLog(@"Done scanning. Total size=%qu, Time taken=%f", 
          [volumeTree itemSize], -[startTime timeIntervalSinceNow]);
  
  return [[[TreeHistory alloc] 
              initWithVolumeTree: volumeTree
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
