#import "AbstractFileItemTest.h"


@implementation AbstractFileItemTest

- (id) init {
  return [self initWithName:@""];
}

- (id) initWithName:(NSString*)nameVal {
  if (self = [super init]) {
    name = [nameVal retain];
  }

  return self;
}

- (void) dealloc {
  [name release];
  
  [super dealloc];
}

- (NSString*) name {
  return name;
}

- (BOOL) testFileItem:(FileItem*)item {
  NSAssert(NO, @"This method must be overridden.");
  return NO;
}

@end
