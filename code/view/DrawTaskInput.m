#import "DrawTaskInput.h"

#import "Item.h"


@implementation DrawTaskInput

- (id) initWithItemTree:(Item*)itemTreeVal bounds:(NSRect)boundsVal {
  if (self = [super init]) {
    itemTree = [itemTreeVal retain];
    bounds = boundsVal;
  }
  return self;
}

- (void) dealloc {
  [itemTree release];
  
  [super dealloc];
}


- (Item*) itemTree {
  return itemTree;
}

- (NSRect) bounds {
  return bounds;
}

@end
