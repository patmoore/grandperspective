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
  
  // The number of folders from the root till the current one.
  int  recursionDepth;
  
  // The stack of autorelease pools that are currently being used.
  NSMutableArray  *autoreleasePoolStack;
    
  // The maximum number of active autorelease pools
  int  maxAutoreleasePools;
  
  // The total number of autorelease pools
  int  numAutoreleasePoolsTotal;
}

- (id) initWithAutoreleasePeriod: (int) period;

@end
