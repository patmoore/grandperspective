#import "ModalityTerminator.h"

#import "ControlConstants.h"

@implementation ModalityTerminator

+ (ModalityTerminator *)modalityTerminatorForEventSource:(NSObject *)source {
  return [[[ModalityTerminator alloc] initWithEventSource: source] autorelease];
}


// Overrides designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithEventSource: instead.");
}

- (id) initWithEventSource:(NSObject *)eventSource {
  if (self = [super init]) {
    NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self selector: @selector(abortModalAction:)
          name: CancelPerformedEvent object: eventSource];
    [nc addObserver: self selector: @selector(abortModalAction:)
          name: ClosePerformedEvent object: eventSource];
          // Closing a window can be considered the same as cancelling.
    [nc addObserver: self selector: @selector(stopModalAction:)
          name: OkPerformedEvent object: eventSource];
  }

  return self;
}

- (void) dealloc {
  NSLog(@"ModalityTerminator -dealloc");
  
  [super dealloc];
}

- (void) abortModalAction:(NSNotification *)notification {
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [NSApp abortModal];
}

- (void) stopModalAction:(NSNotification *)notification {
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [NSApp stopModal];
}

@end // @implementation ModalityTerminator