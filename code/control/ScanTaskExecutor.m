#import "ScanTaskExecutor.h"

#import "ScanProgressPanelControl.h"
#import "FileItem.h"


@implementation ScanTaskExecutor

- (id) init {
  if (self = [super init]) {
    scanProgressPanelControl = [[ScanProgressPanelControl alloc] init];
    enabled = YES;
  }
  return self;
}

- (void) dealloc {
  [scanProgressPanelControl release];
  
  [super dealloc];
}


- (id) runTaskWithInput: (id)input {
  if (enabled) {
    NSString  *dirName = input;
    return [scanProgressPanelControl scanDirectory:dirName];
  }
  else {
    return nil;
  }
}


- (void) disable {
  enabled = NO;
  [scanProgressPanelControl abort:self];
}

- (void) enable {
  enabled = YES;
}

@end
