#import "DrawTaskInput.h"

#import "FileItem.h"
#import "TreeLayoutBuilder.h"


@implementation DrawTaskInput

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithItemTree:bounds: instead");
}

- (id) initWithItemSubTree: (FileItem *)itemTreeVal
         layoutBuilder: (TreeLayoutBuilder *)layoutBuilderVal
         bounds: (NSRect) boundsVal {
  if (self = [super init]) {
    itemTree = [itemTreeVal retain];
    layoutBuilder = [layoutBuilderVal retain];
    bounds = boundsVal;
  }
  return self;
}

- (void) dealloc {
  [itemTree release];
  [layoutBuilder release];
  
  [super dealloc];
}


- (FileItem*) itemSubTree {
  return itemTree;
}

- (TreeLayoutBuilder *) treeLayoutBuilder {
  return layoutBuilder;
}

- (NSRect) bounds {
  return bounds;
}

@end
