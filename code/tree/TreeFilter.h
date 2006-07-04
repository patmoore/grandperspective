#import <Cocoa/Cocoa.h>


@class TreeBalancer;
@class DirectoryItem;
@protocol FileItemTest;


@interface TreeFilter : NSObject {

  TreeBalancer  *treeBalancer;
  NSObject <FileItemTest>  *itemTest;
  
@private
  NSMutableArray*  tmpDirItems;
  NSMutableArray*  tmpFileItems;
}


- (id) initWithFileItemTest:(NSObject <FileItemTest> *)itemTest;

- (DirectoryItem*) filterItemTree:(DirectoryItem*) dirItem;

@end
