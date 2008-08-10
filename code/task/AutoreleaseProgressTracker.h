#import <Cocoa/Cocoa.h>

#import "ProgressTracker.h"


/* A progress tracker that periodically empties the autorelease pool. This is
 * useful managing long-running tasks that may potentially create many
 * autoreleased objects.
 */
@interface AutoreleaseProgressTracker : ProgressTracker {
  // The number of folders that is processed each time before the autorelease 
  // pool is emptied.
  int  autoreleasePeriod;
  
  // The number of folders to process before emptying the autorelease pool  
  int  autoreleaseCountdown;
  
  // The stack of autorelease pools. There is an entry for each folder that
  // is currently being processed. However, not all will have their own
  // autoreleasePool, in which case the stack contains NSNull.
  NSMutableArray  *autoreleasePoolStack;
  
  // The number of active autorelease pools
  int  numAutoreleasePools;
  
  // The maximum number of active autorelease pools
  int  maxAutoreleasePools;
  
  // The total number of autorelease pools
  int  numAutoreleasePoolsTotal;
}

- (id) initWithAutoreleasePeriod: (int) period;

@end
