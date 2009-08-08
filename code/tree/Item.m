#import "Item.h"


@implementation Item

+ (NSZone *) dedicatedZone {
  static NSZone  *dedicatedZone = nil;

  if (dedicatedZone == nil) {
    dedicatedZone = NSCreateZone(8192 * 16, 4096 * 16, YES);
  }

  return dedicatedZone;
}


// Overrides super's designated initialiser.
- (id) init {
  return [self initWithItemSize:0];
}

- (id) initWithItemSize:(ITEM_SIZE)sizeVal {
  if (self = [super init]) {
    size = sizeVal;
  }
  
  return self;
}


- (ITEM_SIZE) itemSize {
  return size;
}

- (FILE_COUNT) numFiles {
  return 0;
}


- (BOOL) isVirtual {
  return NO;
}


- (NSString*) description {
  return [NSString stringWithFormat:@"Item(size=%qu)", size];
}

@end
