#import <Cocoa/Cocoa.h>

#define ITEM_SIZE  unsigned long long


@interface Item : NSObject {
  ITEM_SIZE  size;
}

- (id) initWithItemSize:(ITEM_SIZE)size;

- (ITEM_SIZE) itemSize;

// An item is virtual if it is not a file item (i.e. a file or directory).
- (BOOL) isVirtual;

@end
