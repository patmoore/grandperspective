#import <Cocoa/Cocoa.h>

@class ItemNameTest;
@class ItemPathTest;
@class ItemSizeTest;
@class ItemTypeTest;
@class ItemFlagsTest;
@class SelectiveItemTest;
@class NotItemTest;
@class CompoundAndItemTest;
@class CompoundOrItemTest;


@protocol FileItemTestVisitor 

- (void) visitItemNameTest: (ItemNameTest *)test;
- (void) visitItemPathTest: (ItemPathTest *)test;
- (void) visitItemSizeTest: (ItemSizeTest *)test;
- (void) visitItemTypeTest: (ItemTypeTest *)test;
- (void) visitItemFlagsTest: (ItemFlagsTest *)test;

- (void) visitSelectiveItemTest: (SelectiveItemTest *)test;

- (void) visitNotItemTest: (NotItemTest *)test;
- (void) visitCompoundAndItemTest: (CompoundAndItemTest *)test;
- (void) visitCompoundOrItemTest: (CompoundOrItemTest *)test;

@end
