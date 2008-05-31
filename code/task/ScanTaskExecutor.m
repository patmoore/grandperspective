#import "ScanTaskExecutor.h"

#import "TreeBuilder.h"
#import "DirectoryItem.h"
#import "TreeContext.h"
#import "ScanTaskInput.h"
#import "FilteredTreeGuide.h"


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
  
  NSAssert( treeBuilder==nil, @"treeBuilder already set.");

  ScanTaskInput  *myInput = input;
  FilteredTreeGuide  *treeGuide = 
    [[[FilteredTreeGuide alloc] 
         initWithFileItemTest: [myInput filterTest]
           packagesAsFiles: [myInput packagesAsFiles]] autorelease];

  NSString  *path = [myInput directoryName];
  
  treeBuilder = [[TreeBuilder alloc] initWithFilteredTreeGuide: treeGuide];
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
