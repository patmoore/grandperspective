#import <Cocoa/Cocoa.h>


@class AsynchronousTaskManager;


/* Wraps around an AsynchronousTaskManager to show a progress panel whenever
 * as task is run in the background.
 */
@interface VisibleAsynchronousTaskManager : NSObject {

  AsynchronousTaskManager  *taskManager;
  NSString  *panelTitle;

}


- (id) initWithTaskManager: (AsynchronousTaskManager*) taskManager
         panelTitle: (NSString *)title;

- (void) dispose;


- (void) abortTask;

- (void) asynchronouslyRunTaskWithInput: (id) input 
           description: (NSString *)description
           callback: (NSObject *)callback 
           selector: (SEL) selector;

@end
