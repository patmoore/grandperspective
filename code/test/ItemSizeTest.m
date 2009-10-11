#import "ItemSizeTest.h"

#import "FileItem.h"
#import "FileItemTestVisitor.h"


@implementation ItemSizeTest

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithLowerBound:upperBound: instead.");
}

- (id) initWithLowerBound:(ITEM_SIZE) lowerBoundVal {
  return [self initWithLowerBound: lowerBoundVal upperBound: ULONG_LONG_MAX];
}

- (id) initWithUpperBound:(ITEM_SIZE) upperBoundVal {
  return [self initWithLowerBound: 0 upperBound: upperBoundVal];
}

- (id) initWithLowerBound:(ITEM_SIZE) lowerBoundVal
               upperBound:(ITEM_SIZE) upperBoundVal {
  if (self = [super init]) {
    lowerBound = lowerBoundVal;
    upperBound = upperBoundVal;
  }
  
  return self;
}


// Note: Special case. Does not call own designated initialiser. It should
// be overridden and only called by initialisers with the same signature.
- (id) initWithPropertiesFromDictionary:(NSDictionary *)dict {
  if (self = [super initWithPropertiesFromDictionary: dict]) {
    id  object;
    
    object = [dict objectForKey: @"lowerBound"];
    lowerBound = (object == nil) ? 0 : [object unsignedLongLongValue];
     
    object = [dict objectForKey: @"upperBound"];
    upperBound = (object == nil) ? ULONG_LONG_MAX : 
                                       [object unsignedLongLongValue];
  }
  
  return self;
}

- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  [dict setObject: @"ItemSizeTest" forKey: @"class"];
  
  if ([self hasLowerBound]) {
    [dict setObject: [NSNumber numberWithUnsignedLongLong: lowerBound]
            forKey: @"lowerBound"];
  }
  if ([self hasUpperBound]) {
    [dict setObject: [NSNumber numberWithUnsignedLongLong: upperBound]
            forKey: @"upperBound"];
  }
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

                                    
- (TestResult) testFileItem:(FileItem *)item context:(id) context {
  return ( ([item itemSize] >= lowerBound && 
            [item itemSize] <= upperBound) ? TEST_PASSED : TEST_FAILED );
}

- (BOOL) appliesToDirectories {
  return YES;
}

- (void) acceptFileItemTestVisitor:(NSObject <FileItemTestVisitor> *)visitor {
  [visitor visitItemSizeTest: self];
}


- (NSString *)description {
  if ([self hasLowerBound]) {
    if ([self hasUpperBound]) {
      NSString  *fmt = 
        NSLocalizedStringFromTable( 
          @"size is between %@ and %@", @"Tests", 
          @"Size test with 1: lower bound, and 2: upper bound" );
      return [NSString stringWithFormat: fmt, 
                [FileItem stringForFileItemSize: lowerBound],
                [FileItem stringForFileItemSize: upperBound] ];
    }
    else {
      NSString  *fmt = 
        NSLocalizedStringFromTable( @"size is larger than %@", @"Tests", 
                                    @"Size test with 1: lower bound" );
      
      return [NSString stringWithFormat: fmt,
                [FileItem stringForFileItemSize:lowerBound] ];
    }
  }
  else {
    if ([self hasUpperBound]) {
      NSString  *fmt = 
        NSLocalizedStringFromTable( @"size is smaller than %@", @"Tests", 
                                    @"Size test with 1: upper bound" );
      return [NSString stringWithFormat: fmt,
                [FileItem stringForFileItemSize:upperBound] ];
    }
    else {
      return NSLocalizedStringFromTable( @"any size", @"Tests", 
                                         @"Size test without any bounds" );
    }
  }
}


+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict {
  NSAssert([[dict objectForKey: @"class"] isEqualToString: @"ItemSizeTest"],
             @"Incorrect value for class in dictionary.");

  return [[[ItemSizeTest alloc] initWithPropertiesFromDictionary: dict]
              autorelease];
}

@end // @implementation ItemSizeTest


