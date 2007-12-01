#import "DrawTaskInput.h"

#import "FileItem.h"
#import "TreeLayoutBuilder.h"


@implementation DrawTaskInput

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithVisibleTree:treeInView:layoutBuilder... instead");
}

- (id) initWithVisibleTree: (FileItem *)visibleTreeVal
         treeInView: (FileItem *)treeInViewVal
         layoutBuilder: (TreeLayoutBuilder *)layoutBuilderVal
         bounds: (NSRect) boundsVal {
  if (self = [super init]) {
    visibleTree = [visibleTreeVal retain];
    treeInView = [treeInViewVal retain];
    layoutBuilder = [layoutBuilderVal retain];
    bounds = boundsVal;
  }
  return self;
}

- (void) dealloc {
  [visibleTree release];
  [treeInView release];
  [layoutBuilder release];
  
  [super dealloc];
}


- (FileItem*) visibleTree {
  return visibleTree;
}

- (FileItem*) treeInView {
  return treeInView;
}

- (TreeLayoutBuilder *) layoutBuilder {
  return layoutBuilder;
}

- (NSRect) bounds {
  return bounds;
}

@end
