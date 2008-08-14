#import "Item.h"


@implementation Item

static NSZone  *dedicatedZone = nil;
static BOOL  useDedicatedZone = NO;

+ (void) useDedicatedZone: (BOOL) flag {
  useDedicatedZone = flag;
  if (useDedicatedZone && dedicatedZone == nil) {
    dedicatedZone = NSCreateZone(8192 * 16, 4096 * 16, NO);
  }
}

+ (NSZone *) zone {
  return useDedicatedZone ? dedicatedZone : nil;
}

+ (id) alloc {
  return [Item allocWithZone: [Item zone]];
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


- (BOOL) isVirtual {
  return NO;
}


- (NSString*) description {
  return [NSString stringWithFormat:@"Item(size=%qu)", size];
}

@end
