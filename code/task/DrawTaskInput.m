#import "DrawTaskInput.h"

#import "FileItem.h"
#import "TreeLayoutBuilder.h"


@implementation DrawTaskInput

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithItemTree:bounds: instead");
}

- (id) initWithVisibleTree: (FileItem *)visibleTreeVal
         layoutBuilder: (TreeLayoutBuilder *)layoutBuilderVal
         bounds: (NSRect) boundsVal {
  if (self = [super init]) {
    visibleTree = [visibleTreeVal retain];
    layoutBuilder = [layoutBuilderVal retain];
    bounds = boundsVal;
  }
  return self;
}

- (void) dealloc {
  [visibleTree release];
  [layoutBuilder release];
  
  [super dealloc];
}


- (FileItem*) visibleTree {
  return visibleTree;
}

- (TreeLayoutBuilder *) layoutBuilder {
  return layoutBuilder;
}

- (NSRect) bounds {
  return bounds;
}

@end
