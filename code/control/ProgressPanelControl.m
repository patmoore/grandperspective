#import "ProgressPanelControl.h"

#import "PreferencesPanelControl.h"


@interface ProgressPanelControl (PrivateMethods)

- (void) updatePanel;

@end


@implementation ProgressPanelControl

- (id) init {
  NSAssert(NO, @"Use initWithTaskExecutor: instead.");
}

- (id) initWithTaskExecutor: (NSObject <TaskExecutor> *)taskExecutorVal {
  if (self = [super initWithWindowNibName: @"ProgressPanel" owner: self]) {
    taskExecutor = [taskExecutorVal retain];
    
    refreshRate = [[NSUserDefaults standardUserDefaults] 
                      floatForKey: ProgressPanelRefreshRateKey];
    if (refreshRate <= 0) {
      NSLog(@"Invalid value for progressPanelRefreshRate.");
      refreshRate = 1;
    }
  }
  
  return self;
}


- (void) dealloc {
  [taskExecutor release];

  NSAssert(cancelCallback==nil, @"cancelCallback not nil.");
  
  [super dealloc];  
}


- (void) windowDidLoad {
  [progressDetails setStringValue: @""];
  [progressSummary setStringValue: @""];
}


- (NSObject <TaskExecutor> *) taskExecutor {
  return taskExecutor;
}


- (void) taskStartedWithInput: (id) taskInput
           cancelCallback: (NSObject *)callback selector: (SEL) selector {
  NSAssert( cancelCallback==nil, @"Callback already set." );
  
  cancelCallback = [callback retain];
  cancelCallbackSelector = selector;

  [[self window] center];
  [[self window] orderFront: self];

  [self initProgressInfoForTaskWithInput: taskInput];
  [progressIndicator startAnimation: self];

  taskRunning = YES;
  [self updatePanel];
}

- (void) taskStopped {
  NSAssert( cancelCallback!=nil, @"Callback already nil.");
  
  [cancelCallback release];
  cancelCallback = nil;
  
  [progressIndicator stopAnimation: self];  

  [[self window] close];

  taskRunning = NO;  
}


- (IBAction) abort: (id) sender {
  [cancelCallback performSelector: cancelCallbackSelector];
 
  // No need to invoke "taskStopped". This is the responsibility of the caller
  // of "taskStarted".
}

@end // @implementation ProgressPanelControl


@implementation ProgressPanelControl (ProtectedMethods)

- (void) initProgressInfoForTaskWithInput: (id) taskInput {
  // void. To be overridden
}

- (void) updateProgressInfo {
  // void. To be overridden
}

@end // @implementation ProgressPanelControl (ProtectedMethods)


@implementation ProgressPanelControl (PrivateMethods)

- (void) updatePanel {
  if (!taskRunning) {
    return;
  }

  [self updateProgressInfo];

  // Schedule another update    
  [self performSelector: @selector(updatePanel) withObject: 0 
          afterDelay: refreshRate];
}

@end // @implementation ProgressPanelControl (PrivateMethods)


