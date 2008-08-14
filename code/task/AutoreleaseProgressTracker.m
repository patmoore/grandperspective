#import "AutoreleaseProgressTracker.h"


/* Helper object, needed because an autorelease pool cannot be retained.
 */
@interface AutoreleasePoolProxy : NSObject {
  NSAutoreleasePool  *pool;
}

@end


@implementation AutoreleaseProgressTracker

- (id) init {
  return [self initWithAutoreleasePeriod: 64];
}

- (id) initWithAutoreleasePeriod: (int) period {
  if (self = [super init]) {
    autoreleasePeriod = period;

    autoreleasePoolStack = [[NSMutableArray alloc] initWithCapacity: 16];
    numAutoreleasePools = 0;
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

  autoreleaseCountdown = autoreleasePeriod;
  numAutoreleasePoolsTotal = 0;
  maxAutoreleasePools = 0;

  [super startingTask];
}

- (void) finishedTask {
  [super finishedTask];
  
  NSLog(@"Autorelease pools: max active=%d, total created=%d", 
          maxAutoreleasePools, numAutoreleasePoolsTotal);

  while ([autoreleasePoolStack count] > 0) {
    if ([autoreleasePoolStack lastObject] != [NSNull null]) {
      numAutoreleasePools--;
    }
  
    [autoreleasePoolStack removeLastObject];
  }
  NSAssert( numAutoreleasePools == 0, @"Pool count mismatch.");
}


- (void) processingFolder: (DirectoryItem *)dirItem {
  [super processingFolder: dirItem];
  
  if (autoreleaseCountdown-- <= 0) {
    AutoreleasePoolProxy  *poolProxy =  [[AutoreleasePoolProxy alloc] init];
    [autoreleasePoolStack addObject: poolProxy];
    [poolProxy release]; // Release it so that only the stack is retaining it.
    
    numAutoreleasePools++;
    numAutoreleasePoolsTotal++;
    if (numAutoreleasePools > maxAutoreleasePools) {
      maxAutoreleasePools = numAutoreleasePools;
    }
    autoreleaseCountdown = autoreleasePeriod;

    //NSLog(@"Created pool: active=%d, total=%d", 
    //        numAutoreleasePools, numAutoreleasePoolsTotal);
  }
  else {
    [autoreleasePoolStack addObject: [NSNull null]];
  }
}


- (void) processedFolder: (DirectoryItem *)dirItem {
  if ([autoreleasePoolStack lastObject] != [NSNull null]) {
    numAutoreleasePools--;
    autoreleaseCountdown = 0; // Create a new one asap.
  }
  
  [autoreleasePoolStack removeLastObject];

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
