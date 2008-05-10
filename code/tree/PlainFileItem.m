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


- (FileItem *) duplicateFileItem: (DirectoryItem *)newParent {
  return [[[PlainFileItem alloc] initWithName: name 
                                   parent: newParent
                                   size: size
                                   type: type] autorelease];
}


- (UniformType *)uniformType {
  return type;
}

@end
