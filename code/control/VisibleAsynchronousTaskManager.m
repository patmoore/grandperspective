#import "VisibleAsynchronousTaskManager.h"


#import "AsynchronousTaskManager.h"
#import "ProgressPanelControl.h"


@interface CallbackHandler : NSObject {  
  ProgressPanelControl  *progressPanelControl;

  NSObject  *callback;
  SEL  callbackSelector;   
}

- (id) initWithProgressPanel: (ProgressPanelControl *)progressPanel
         callback: (NSObject *)callback selector: (SEL) selector;
         
- (void) taskDone: (id) result;

@end // @interface CallbackHandler


@implementation VisibleAsynchronousTaskManager

// Overrides super's designated initialiser.
- (id) init {
  NSAssert(NO, @"Use -initWithTaskMamager:panelTitle instead.");
}

- (id) initWithTaskManager: (AsynchronousTaskManager*) taskManagerVal
         panelTitle: (NSString*) title {
  if (self = [super init]) {
    taskManager = [taskManagerVal retain];
    panelTitle = [title retain];
  }

  return self;
}

- (void) dealloc {
  [taskManager release];
  [panelTitle release];

  [super dealloc];
}

- (void) dispose {
  NSAssert( taskManager != nil, @"TaskManager already nil.");
  [taskManager dispose];

  // Set it to "nil" to prevent it from being disposed once more.
  [taskManager release];
  taskManager = nil;
}


- (void) abortTask {
  [taskManager abortTask];
}


- (void) asynchronouslyRunTaskWithInput: (id) input 
           description: (NSString *)description
           callback: (NSObject *)callback 
           selector: (SEL) selector {
  ProgressPanelControl  *progressPanel = 
    [[ProgressPanelControl alloc] initWithTitle: panelTitle];

  // Show the progess panel and let its Cancel button abort the task.
  [progressPanel taskStarted: description
                   cancelCallback: taskManager
                   selector: @selector(abortTask) ];

  CallbackHandler  *callbackHandler = 
    [[CallbackHandler alloc] initWithProgressPanel: progressPanel
                               callback: callback
                               selector: selector];

  // Let callback go through handler object, so that progress panel is also
  // closed.
  [taskManager asynchronouslyRunTaskWithInput: input 
                 callback: callbackHandler 
                 selector: @selector(taskDone:) ];
                 
  [callbackHandler release];
  [progressPanel release];
}

@end // @implementation VisibleAsynchronousTaskManager


@implementation CallbackHandler

// Overrides super's designated initialiser.
- (id) init {
  NSAssert(NO, @"Use -initWithProgressPanel:callback:selector instead.");
}

- (id) initWithProgressPanel: (ProgressPanelControl *)panelControl
         callback: (NSObject *)callbackVal selector: (SEL) selector {

  if (self = [super init]) {
    progressPanelControl = [panelControl retain];
    callback = [callbackVal retain];
    callbackSelector = selector;
  }
  
  return self;
}

- (void) dealloc {
  [progressPanelControl release];
  [callback release];
  
  [super dealloc];
}

- (void) taskDone: (id) result {
  [progressPanelControl taskStopped];
  
  [callback performSelector: callbackSelector withObject: result];
}


@end // @implementation CallbackHandler
