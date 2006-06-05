#import "ItemSizeTest.h"


@implementation ItemSizeTest

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithLowerBound:upperBound: instead.");
}

- (id) initWithLowerBound:(ITEM_SIZE)lowerBoundVal {
  return [self initWithLowerBound:lowerBoundVal upperBound:ULONG_LONG_MAX];
}

- (id) initWithUpperBound:(ITEM_SIZE)upperBoundVal {
  return [self initWithLowerBound:0 upperBound:upperBoundVal];
}

- (id) initWithLowerBound:(ITEM_SIZE)lowerBoundVal
               upperBound:(ITEM_SIZE)upperBoundVal {
  if (self = [super init]) {
    lowerBound = lowerBoundVal;
    upperBound = upperBoundVal;
  }
  
  return self;
}

- (BOOL) hasLowerBound {
  return (lowerBound > 0);
}

- (BOOL) hasUpperBound {
  return (upperBound < ULONG_LONG_MAX);
}

- (ITEM_SIZE) lowerBound {
  return lowerBound;
}

- (ITEM_SIZE) upperBound {
  return upperBound;
}

                                    
- (BOOL) testFileItem:(FileItem*)item {
  return ([item itemSize] >= lowerBound && 
          [item itemSize] <= upperBound);
}

- (NSString*) description {
  // TODO: show "kB", "MB", or "GB" if needed.
  
  if ([self hasLowerBound]) {
    return [self hasUpperBound] ?
      [NSString stringWithFormat:@"size is between %qu and %qu", lowerBound,
                                                                 upperBound] :
      [NSString stringWithFormat:@"size is larger than %qu", lowerBound];
  }
  else {
    return [self hasUpperBound] ?
      [NSString stringWithFormat:@"size is smaller than %qu", upperBound] :
      @"any size";
  }
}

@end
