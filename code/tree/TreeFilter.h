#import <Cocoa/Cocoa.h>


@class TreeBalancer;
@class DirectoryItem;
@class FileItemPathStringCache;
@protocol FileItemTest;


@interface TreeFilter : NSObject {

  TreeBalancer  *treeBalancer;
  NSObject <FileItemTest>  *itemTest;

  FileItemPathStringCache  *fileItemPathStringCache;

  BOOL  abort;
  
@private
  NSMutableArray*  tmpDirItems;
  NSMutableArray*  tmpFileItems;
}


- (id) initWithFileItemTest:(NSObject <FileItemTest> *)itemTest;

- (DirectoryItem*) filterVolumeTree:(DirectoryItem *)volumeTree;

- (void) abort;

@end
