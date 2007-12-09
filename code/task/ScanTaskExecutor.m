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
  
  TreeContext*  scanResult = [treeBuilder buildTreeForPath: path];
  
  [treeBuilder release];
  treeBuilder = nil;
  
  if (scanResult != nil) {
    NSLog(@"Done scanning. Time taken=%f", -[startTime timeIntervalSinceNow]);
  }

  return scanResult;
}


- (void) disable {
  enabled = NO;

  [treeBuilder abort];
}


- (void) enable {
  enabled = YES;
}

@end
