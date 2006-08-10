#import "DrawTaskInput.h"

#import "FileItem.h"


@implementation DrawTaskInput

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithItemTree:bounds: instead");
}

- (id) initWithItemSubTree: (FileItem *)tree bounds: (NSRect) boundsVal {
  if (self = [super init]) {
    itemTree = [tree retain];
    bounds = boundsVal;
  }
  return self;
}

- (void) dealloc {
  [itemTree release];
  
  [super dealloc];
}


- (FileItem*) itemSubTree {
  return itemTree;
}

- (NSRect) bounds {
  return bounds;
}

@end
