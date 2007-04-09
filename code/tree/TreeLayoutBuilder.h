#import <Cocoa/Cocoa.h>

@class Item;
@protocol TreeLayoutTraverser;

@interface TreeLayoutBuilder : NSObject {
  unsigned long long  freeSpace;
  BOOL  showFreeSpace;
}

- (void) layoutItemTree:(Item *)itemTreeRoot inRect:(NSRect)bounds
           traverser:(NSObject <TreeLayoutTraverser> *)traverser;

- (void) setFreeSpace: (unsigned long long) space;
- (unsigned long long) freeSpace;

- (void) setShowFreeSpace: (BOOL) flag;
- (BOOL) showFreeSpace;

@end
