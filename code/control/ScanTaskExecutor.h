#import <Cocoa/Cocoa.h>

#import "TaskExecutor.h"

@class ScanProgressPanelControl;

@interface ScanTaskExecutor : NSObject <TaskExecutor> {
  ScanProgressPanelControl  *scanProgressPanelControl;
  BOOL  enabled;
}

@end
