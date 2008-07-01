#import <Cocoa/Cocoa.h>

#import "ProgressPanelControl.h"


@class ScanTaskExecutor;

@interface ScanProgressPanelControl : ProgressPanelControl {

  BOOL  taskRunning;
  ScanTaskExecutor  *scanTaskExecutor;

}

- (id) initWithTitle: (NSString *)title  
         scanTaskExecutor: (ScanTaskExecutor *)taskExecutor;

@end
