#import "ScanTaskExecutor.h"

#import "TreeBuilder.h"
#import "DirectoryItem.h"
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
  if ([[myInput fileSizeType] isEqualToString: @"logical"]) {
    [treeBuilder setFileSizeType: LOGICAL_FILE_SIZE];
  }
  else if ([[myInput fileSizeType] isEqualToString: @"physical"]) {
    [treeBuilder setFileSizeType: PHYSICAL_FILE_SIZE];
  }
  
  NSDate  *startTime = [NSDate date];
  
  DirectoryItem*  itemTreeRoot = 
    [treeBuilder buildTreeForPath: [myInput directoryName]];
  
  [treeBuilder release];
  treeBuilder = nil;
  
  if (itemTreeRoot != nil) {
    NSLog(@"Done scanning. Total size=%qu, Time taken=%f", 
            [itemTreeRoot itemSize], -[startTime timeIntervalSinceNow]);
  }
  
  return itemTreeRoot;
}


- (void) disable {
  enabled = NO;

  [treeBuilder abort];
}


- (void) enable {
  enabled = YES;
}

@end
