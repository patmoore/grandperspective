#import "ItemSizeTest.h"

#import "FileItem.h"

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
  if ([self hasLowerBound]) {
    if ([self hasUpperBound]) {
      NSString  *fmt = 
        NSLocalizedStringFromTable( 
          @"size is between %@ and %@", @"tests", 
          @"Size test with 1: lower bound, and 2: upper bound" );
      return [NSString stringWithFormat: fmt, 
                [FileItem stringForFileItemSize: lowerBound],
                [FileItem stringForFileItemSize: upperBound] ];
    }
    else {
      NSString  *fmt = 
        NSLocalizedStringFromTable( @"size is larger than %@", @"tests", 
                                    @"Size test with 1: lower bound" );
      
      return [NSString stringWithFormat: fmt,
                [FileItem stringForFileItemSize:lowerBound] ];
    }
  }
  else {
    if ([self hasUpperBound]) {
      NSString  *fmt = 
        NSLocalizedStringFromTable( @"size is smaller than %@", @"tests", 
                                    @"Size test with 1: upper bound" );
      return [NSString stringWithFormat: fmt,
                [FileItem stringForFileItemSize:upperBound] ];
    }
    else {
      return NSLocalizedStringFromTable( @"any size", @"tests", 
                                         @"Size test without any bounds" );
    }
  }
}

@end
