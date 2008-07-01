#import "VisibleAsynchronousScanTaskManager.h"

#import "AsynchronousTaskManager.h"
#import "ScanProgressPanelControl.h"


@implementation VisibleAsynchronousScanTaskManager

- (ScanProgressPanelControl *) createProgressPanelControl {
  return [[[ScanProgressPanelControl alloc] 
              initWithTitle: panelTitle
              scanTaskExecutor: (ScanTaskExecutor *)[taskManager taskExecutor]
          ] autorelease];
}

@end
