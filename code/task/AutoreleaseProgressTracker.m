#import "AutoreleaseProgressTracker.h"


/* Helper object, needed because an autorelease pool cannot be retained.
 */
@interface AutoreleasePoolProxy : NSObject {
  NSAutoreleasePool  *pool;
}

@end


@implementation AutoreleaseProgressTracker

- (id) init {
  return [self initWithAutoreleasePeriod: 2];
}

- (id) initWithAutoreleasePeriod: (int) period {
  if (self = [super init]) {
    autoreleasePeriod = period;

    autoreleasePoolStack = [[NSMutableArray alloc] initWithCapacity: 16];
  }
  
  return self;
}

- (void) dealloc {
  [autoreleasePoolStack release];
  
  [super dealloc];
}


- (void) startingTask {
  NSAssert( [autoreleasePoolStack count] == 0, 
            @"autoreleasePoolStack should be empty." );

  recursionDepth = 0;
  numAutoreleasePoolsTotal = 0;
  maxAutoreleasePools = 0;

  [super startingTask];
}

- (void) finishedTask {
  [super finishedTask];
  
  // NSLog(@"Autorelease pools: max active=%d, total created=%d", 
  //        maxAutoreleasePools, numAutoreleasePoolsTotal);

  while ([autoreleasePoolStack count] > 0) {
    [autoreleasePoolStack removeLastObject];
  }
}


- (void) processingFolder: (DirectoryItem *)dirItem {
  [super processingFolder: dirItem];
  
  recursionDepth++;
  if (recursionDepth % autoreleasePeriod == 0) {
    AutoreleasePoolProxy  *poolProxy =  [[AutoreleasePoolProxy alloc] init];
    [autoreleasePoolStack addObject: poolProxy];
    [poolProxy release]; // Release it so that only the stack is retaining it.
    
    numAutoreleasePoolsTotal++;
    if ([autoreleasePoolStack count] > maxAutoreleasePools) {
      maxAutoreleasePools = [autoreleasePoolStack count];
    }
  }
}


- (void) processedFolder: (DirectoryItem *)dirItem {
  if (recursionDepth % autoreleasePeriod == 0) {
    [autoreleasePoolStack removeLastObject];
  }
  recursionDepth--;
  
  [super processedFolder: dirItem];
}

@end


@implementation AutoreleasePoolProxy

- (id) init {
  if (self = [super init]) {
    pool =  [[NSAutoreleasePool alloc] init];
  }
  return self;
}

- (void) dealloc {
  [pool release];
  
  [super dealloc];
}

@end
