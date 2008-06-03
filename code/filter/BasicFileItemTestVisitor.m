#import "BasicFileItemTestVisitor.h"

#import "SelectiveItemTest.h"
#import "NotItemTest.h"
#import "CompoundItemTest.h"
#import "CompoundAndItemTest.h"
#import "CompoundOrItemTest.h"

@interface BasicFileItemTestVisitor (PrivateMethods)

- (void) visitCompoundItemTest: (CompoundItemTest *)test;

@end


@implementation BasicFileItemTestVisitor

- (void) visitItemNameTest: (ItemNameTest *)test {}
- (void) visitItemPathTest: (ItemPathTest *)test {}
- (void) visitItemSizeTest: (ItemSizeTest *)test {}
- (void) visitItemTypeTest: (ItemTypeTest *)test {}
- (void) visitItemFlagsTest: (ItemFlagsTest *)test {}

- (void) visitSelectiveItemTest: (SelectiveItemTest *)test {
  [[test subItemTest] acceptFileItemTestVisitor: self];
}

- (void) visitNotItemTest: (NotItemTest *)test {
  [[test subItemTest] acceptFileItemTestVisitor: self];
}

- (void) visitCompoundAndItemTest: (CompoundAndItemTest *)test {
  [self visitCompoundItemTest: test];
}

- (void) visitCompoundOrItemTest: (CompoundOrItemTest *)test {
  [self visitCompoundItemTest: test];
}

@end


@implementation BasicFileItemTestVisitor (PrivateMethods)

- (void) visitCompoundItemTest: (CompoundItemTest *)test {
  NSEnumerator  *subItemTestEnum = [[test subItemTests] objectEnumerator];
  NSObject <FileItemTest>  *subItemTest;
  
  while (subItemTest = [subItemTestEnum nextObject]) {
    [subItemTest acceptFileItemTestVisitor: self];
  }
}

@end

