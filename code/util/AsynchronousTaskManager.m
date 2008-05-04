#import "AsynchronousTaskManager.h"


#import "TaskExecutor.h"


enum {
  // Indicates that there is a task in progress or ready to be executed.
  BACKGROUND_THREAD_BUSY = 456,

  // Indicates that the thread can block or is blocking, waiting for a new
  // task (or waiting for the manager to be disposed).
  BACKGROUND_THREAD_IDLE, 
  
  // Indicates that the manager is being disposed off and that the thread
  // should terminate.
  BACKGROUND_THREAD_SHUTDOWN
};


@interface AsynchronousTaskManager (PrivateMethods)

- (void) taskRunningLoop;

@end


@implementation AsynchronousTaskManager

// Overrides super's designated initialiser.
- (id) init {
  NSAssert(NO, @"Use -initWithTaskExecutor: instead.");
}

- (id) initWithTaskExecutor: (NSObject <TaskExecutor>*)executorVal {
  if (self = [super init]) {
    executor = [executorVal retain];
  
    workLock = [[NSConditionLock alloc] 
                   initWithCondition:BACKGROUND_THREAD_IDLE];
    settingsLock = [[NSLock alloc] init];
    alive = YES;

    [NSThread detachNewThreadSelector:@selector(taskRunningLoop)
                toTarget:self withObject:nil];
  }
  return self;
}


- (void) dealloc {
  NSAssert(!alive, @"Deallocating without a dispose.");

  [executor release];
  
  [workLock release];
  [settingsLock release];
  
  [nextTaskInput release];
  [nextTaskCallback release];
  
  [super dealloc];
}


- (void) dispose {
  [settingsLock lock];
  NSAssert(alive, @"Disposing of an already dead task manager.");

  alive = NO;

  if ([workLock condition] == BACKGROUND_THREAD_BUSY) {
    // Abort running task
    [executor disable];
  }
  else {
    // Notify the blocked thread (waiting on the BUSY condition)
    [workLock lock];
    [workLock unlockWithCondition: BACKGROUND_THREAD_BUSY];
  }
  
  [settingsLock unlock];
}


- (NSObject <TaskExecutor>*) taskExecutor {
  return executor;
}


- (void) abortTask {
  if ([workLock condition] == BACKGROUND_THREAD_BUSY) {
    // Abort task
    [executor disable];
  }
}


- (void) asynchronouslyRunTaskWithInput: (id) input callback: (id) callback 
           selector: (SEL) selector {

  [settingsLock lock];
  NSAssert(alive, @"Disturbing a dead task manager.");
  
  if (input != nextTaskInput) {
    [nextTaskInput release];
    nextTaskInput = [input retain];
  }
  if (callback != nextTaskCallback) {
    [nextTaskCallback release];
    nextTaskCallback = [callback retain];
  }
  nextTaskCallbackSelector = selector;

  if ([workLock condition] == BACKGROUND_THREAD_BUSY) {
    // Abort task 
    [executor disable];
  }
  else if ([workLock condition] == BACKGROUND_THREAD_IDLE) {
    // Notify the blocked thread (waiting on the BUSY condition)
    [workLock lock];
    [workLock unlockWithCondition: BACKGROUND_THREAD_BUSY];
  }
  else {
    NSAssert(NO, @"Unexpected state of workLock condition.");
  }

  [settingsLock unlock];
}

@end


@implementation AsynchronousTaskManager (PrivateMethods)

- (void) taskRunningLoop {
  do {
    NSAutoreleasePool  *pool = [[NSAutoreleasePool alloc] init];

    // Wait for a task to be carried out.
    [workLock lockWhenCondition: BACKGROUND_THREAD_BUSY];
            
    [settingsLock lock];
    if (alive) {
      NSAssert(nextTaskInput != nil, @"Task not set properly.");
      id  taskInput = [nextTaskInput autorelease];
      NSObject  *taskCallback = [nextTaskCallback autorelease];
      SEL  taskCallbackSelector = nextTaskCallbackSelector;
      nextTaskInput = nil;
      nextTaskCallback = nil;
      
      // The previous task may have been aborted. Make sure that the executor
      // is enabled again (it may be aborted again of course).
      //
      // Note: This should happen in a "settingsLock" block, and can therefore
      // not be done by the executor in its runTaskWithInput: method.
      [executor enable];

      [settingsLock unlock]; // Don't lock settings while running the task.
      id  taskOutput = [executor runTaskWithInput:taskInput];
      [settingsLock lock];
      
      [taskCallback performSelectorOnMainThread: taskCallbackSelector
                      withObject: taskOutput waitUntilDone: NO];
            
      if (!alive) {
        // The manager has been disposed of while BUSY.
        [workLock unlockWithCondition: BACKGROUND_THREAD_SHUTDOWN];
      }
      else if (nextTaskInput == nil) {      
        [workLock unlockWithCondition: BACKGROUND_THREAD_IDLE];
      }
      else {
        [workLock unlockWithCondition: BACKGROUND_THREAD_BUSY];
      }
    }
    else {
      // The manager has been disposed of while IDLE.
      [workLock unlockWithCondition: BACKGROUND_THREAD_SHUTDOWN];
    }
    [settingsLock unlock];
    
    [pool release];
  } while ([workLock condition] != BACKGROUND_THREAD_SHUTDOWN);

  NSLog(@"Thread terminated.");
}

@end // @implementation AsynchronousTaskManager (PrivateMethods)

