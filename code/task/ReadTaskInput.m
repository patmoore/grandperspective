#import "ReadTaskInput.h"


@implementation ReadTaskInput

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithPath: instead");
}

- (id) initWithPath: (NSString *)pathVal {
  if (self = [super init]) {
    path = [pathVal retain];
  }
  
  return self;
}

- (void) dealloc {
  [path release];
  
  [super dealloc];
}

- (NSString *) path {
  return path;
}

@end
