#import "WriteTaskInput.h"


@implementation WriteTaskInput

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithTreeContext:path: instead");
}

- (id) initWithTreeContext: (TreeContext *)context path: (NSString *)pathVal {
  if (self = [super init]) {
    treeContext = [context retain];
    path = [pathVal retain];
  }
  
  return self;
}

- (void) dealloc {
  [treeContext release];
  [path release];
  
  [super dealloc];
}

- (TreeContext *)treeContext {
  return treeContext;
}

- (NSString *) path {
  return path;
}

@end
