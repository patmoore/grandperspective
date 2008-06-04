#import "ItemSizeTestFinder.h"


@implementation ItemSizeTestFinder

- (id) init {
  if (self = [super init]) {
    itemSizeTestFound = NO;
  }
  
  return self;
}


- (void) reset {
  itemSizeTestFound = NO;
}

- (BOOL) itemSizeTestFound {
  return itemSizeTestFound;
}


- (void) visitItemSizeTest: (ItemSizeTest *)test {
  itemSizeTestFound = YES;
}

@end
