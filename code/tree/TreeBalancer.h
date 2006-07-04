#import <Cocoa/Cocoa.h>


@class Item;

@interface TreeBalancer : NSObject {

@private
  NSMutableArray*  tmpArray;
}

// Note: assumes that array may be modified for sorting!
- (Item*) createTreeForItems:(NSMutableArray*)items;

@end
