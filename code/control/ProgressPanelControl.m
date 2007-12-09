#import "ProgressPanelControl.h"


@implementation ProgressPanelControl

- (id) init {
  return [self initWithTitle: nil];
}

- (id) initWithTitle: (NSString*) titleVal {
  if (self = [super initWithWindowNibName: @"ProgressPanel" owner: self]) {
    title = [titleVal retain];
  }
  
  return self;
}


- (void) dealloc {
  [title release];
  [cancelCallback release];
  
  [super dealloc];  
}


- (void) taskStarted: (NSString *)taskDescription
           cancelCallback: (NSObject *)callback selector: (SEL) selector {
  NSAssert( cancelCallback==nil, @"Callback already set." );
  
  cancelCallback = [callback retain];
  cancelCallbackSelector = selector;

  [[self window] setTitle: title];

  [progressText setStringValue: taskDescription];

  [[self window] center];
  [[self window] orderFront: self];

  [progressIndicator startAnimation: self];
}

- (void) taskStopped {
  NSAssert( cancelCallback!=nil, @"Callback already nil.");
  
  [cancelCallback release];
  cancelCallback = nil;
  
  [progressIndicator stopAnimation: self];  
  
  [[self window] close];
}


- (IBAction) abort: (id) sender {
  [cancelCallback performSelector: cancelCallbackSelector];
 
  // No need to invoke "taskStopped". This is the responsibility of the caller
  // of "taskStarted".
}

@end
