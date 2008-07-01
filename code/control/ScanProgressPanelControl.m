#import "ScanProgressPanelControl.h"

#import "ScanTaskExecutor.h"
#import "TreeBuilder.h"


@interface ScanProgressPanelControl (PrivateMethods)

- (void) updatePanel;

@end


@implementation ScanProgressPanelControl

// Overrides designated initialiser.
- (id) initWithTitle: (NSString *)title {
  NSAssert(NO, @"Use initWithTitle:scanTaskExecutor: instead.");
}

- (id) initWithTitle: (NSString *)titleVal 
         scanTaskExecutor: (ScanTaskExecutor *)taskExecutor {
  if (self = [super initWithTitle: titleVal]) {
    scanTaskExecutor = [taskExecutor retain];
  }
  
  return self;
}

- (void) dealloc {
  [scanTaskExecutor release];
  
  [super dealloc];
}


- (void) taskStarted: (NSString*) taskDescription
           cancelCallback: (NSObject*) callback selector: (SEL) selector {
  [super taskStarted: taskDescription 
           cancelCallback: callback selector: selector];
           
  taskRunning = YES;

  [self updatePanel];
}
           
- (void) taskStopped {
  taskRunning = NO;
  
  [super taskStopped];
}

@end // @implementation ScanProgressPanelControl


@implementation ScanProgressPanelControl (PrivateMethods)

- (void) updatePanel {
  if (!taskRunning) {
    return;
  }
  
  NSDictionary  *dict = [scanTaskExecutor scanProgressInfo];
  
  int  numFoldersScanned = [[dict objectForKey: NumFoldersBuiltKey] intValue];
       
  NSLog(@"%d\t%@", numFoldersScanned, 
          [dict objectForKey: CurrentFolderPathKey]);
  
  [self performSelector: @selector(updatePanel) withObject: 0 afterDelay: 1];
}

@end // @implementation ScanProgressPanelControl (PrivateMethods)

