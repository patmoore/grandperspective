#import <Cocoa/Cocoa.h>

#import "Item.h"

@class FileItem;

@interface ItemInventory : NSObject {

  NSMutableSet  *typedExtensions;
  NSMutableSet  *untypedExtensions;
  NSMutableSet  *fileTypes;
      
  int        numTyped;
  ITEM_SIZE  totalSizeTyped;
  
  int        numUntyped;
  ITEM_SIZE  totalSizeUntyped;
}

- (void) registerFileItem: (FileItem *)item;

- (void) dumpItemReport;

@end
