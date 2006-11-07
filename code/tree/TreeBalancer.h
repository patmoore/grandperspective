#import <Cocoa/Cocoa.h>


@class Item;

@interface TreeBalancer : NSObject {

  BOOL  excludeZeroSizedItems;

@private
  NSMutableArray*  tmpArray;
}

- (void) setExcludeZeroSizedItems: (BOOL)flag;
- (BOOL) excludeZeroSizedItems;

// Note: assumes that array may be modified for sorting!
- (Item*) createTreeForItems: (NSMutableArray*)items;

@end
