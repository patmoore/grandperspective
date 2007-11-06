#import <Cocoa/Cocoa.h>


@class TreeBalancer;
@class DirectoryItem;
@class ItemInventory;


extern NSString  *LogicalFileSize;
extern NSString  *PhysicalFileSize;


@interface TreeBuilder : NSObject {

  NSString  *fileSizeMeasure;
  BOOL  useLogicalFileSize;
  
  BOOL  abort;
  TreeBalancer  *treeBalancer;

  // TEMP
  ItemInventory  *itemInventory;
}

- (id) init;

- (void) abort;

- (NSString *) fileSizeMeasure;
- (void) setFileSizeMeasure: (NSString *)measure;

- (DirectoryItem *) buildTreeForPath: (NSString *)path;

@end
