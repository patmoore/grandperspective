#import "PlainFileItem.h"

#import "UniformType.h"

@implementation PlainFileItem

- (id) initWithName: (NSString *)nameVal parent: (DirectoryItem *)parentVal 
         size: (ITEM_SIZE) sizeVal {
  return [self initWithName: nameVal parent: parentVal size: sizeVal type: nil];
}

- (id) initWithName: (NSString *)nameVal parent: (DirectoryItem *)parentVal 
         size: (ITEM_SIZE) sizeVal type: (UniformType *)typeVal {
  if (self = [super initWithName: nameVal parent: parentVal size: sizeVal]) {
    type = [typeVal retain];
  }
  
  return self;
}

- (void) dealloc {
  [type release];
  
  [super dealloc];
}

- (UniformType *)uniformType {
  return type;
}

@end
