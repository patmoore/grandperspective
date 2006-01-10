#import <Cocoa/Cocoa.h>

#define ITEM_SIZE  unsigned long long


@interface Item : NSObject {
  ITEM_SIZE  size;
}

- (id) initWithItemSize:(ITEM_SIZE)size;

- (ITEM_SIZE) itemSize;

- (BOOL) isVirtual;

@end
