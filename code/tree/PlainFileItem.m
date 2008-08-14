#import "PlainFileItem.h"

#import "UniformType.h"

@implementation PlainFileItem

+ (id) alloc {
  return [PlainFileItem allocWithZone: [Item zone]];
}


// Overrides designated initialiser
- (id) initWithName: (NSString *)nameVal parent: (DirectoryItem *)parentVal 
         size: (ITEM_SIZE) sizeVal flags: (UInt8) flagsVal {
  return [self initWithName: nameVal parent: parentVal size: sizeVal 
                 type: nil flags: flagsVal];
}

- (id) initWithName: (NSString *)nameVal parent: (DirectoryItem *)parentVal 
         size: (ITEM_SIZE) sizeVal type: (UniformType *)typeVal {
  return [self initWithName: nameVal parent: parentVal size: sizeVal 
                 type: typeVal flags: 0];
}

- (id) initWithName: (NSString *)nameVal parent: (DirectoryItem *)parentVal 
         size: (ITEM_SIZE) sizeVal type: (UniformType *)typeVal 
         flags: (UInt8) flagsVal {
  if (self = [super initWithName: nameVal parent: parentVal size: sizeVal
                      flags: flagsVal]) {
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
                                   type: type
                                   flags: flags] autorelease];
}


- (UniformType *)uniformType {
  return type;
}

@end
