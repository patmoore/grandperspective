#import "ConstrainedTreeLayoutBuilder.h"

#import "Item.h"


@implementation ConstrainedTreeLayoutBuilder

- (id) initWithReservedSpace: (unsigned long long) reservedSpaceVal {
  if (self = [super init]) {
    reservedSpace = reservedSpaceVal;
  }
  
  return self;
}


- (unsigned long long) reservedSpace {
  return reservedSpace;
}


- (void) layoutItemTree: (Item *)tree 
           inRect: (NSRect) bounds
           traverser: (NSObject <TreeLayoutTraverser> *)traverser {
  unsigned long long  totalSize = reservedSpace + [tree itemSize];

  float  ratio = (totalSize > 0) ? ([tree itemSize] / (float)totalSize) : 0.50;

  NSRect  rect1, rect2;

  if (NSWidth(bounds) > NSHeight(bounds)) {
    NSDivideRect(bounds, &rect1, &rect2, ratio*NSWidth(bounds), NSMinXEdge);
  }
  else {
    NSDivideRect(bounds, &rect1, &rect2, ratio*NSHeight(bounds), NSMaxYEdge); 
  }
        
  [super layoutItemTree: tree inRect: rect1 traverser: traverser];
}

@end
