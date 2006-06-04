#import "ItemSizeTest.h"


@implementation ItemSizeTest

- (id) initWithName:(NSString*)nameVal lowerBound:(ITEM_SIZE)lowerBoundVal {
  return [self initWithName:nameVal lowerBound:lowerBoundVal 
                                    upperBound:ULONG_LONG_MAX];
}

- (id) initWithName:(NSString*)nameVal upperBound:(ITEM_SIZE)upperBoundVal {
  return [self initWithName:nameVal lowerBound:0 
                                    upperBound:upperBoundVal];
}

- (id) initWithName:(NSString*)nameVal lowerBound:(ITEM_SIZE)lowerBoundVal
                                       upperBound:(ITEM_SIZE)upperBoundVal {
  if (self = [super initWithName:nameVal]) {
    lowerBound = lowerBoundVal;
    upperBound = upperBoundVal;
  }
  
  return self;
}
                                    
- (BOOL) testFileItem:(FileItem*)item {
  return ([item itemSize] >= lowerBound && 
          [item itemSize] <= upperBound);
}

- (NSString*) description {
  // TODO: show "kB", "MB", or "GB" if needed.
  
  if (lowerBound == 0) {
    return (upperBound == ULONG_LONG_MAX) ?
      @"any size" :
      [NSString stringWithFormat:@"size is smaller than %qu", upperBound];
  }
  else {
    return (upperBound == ULONG_LONG_MAX) ?
      [NSString stringWithFormat:@"size is larger than %qu", lowerBound] :
      [NSString stringWithFormat:@"size is between %qu and %qu", lowerBound,
                                                                 upperBound];
  }
}

@end
