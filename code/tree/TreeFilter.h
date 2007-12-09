#import <Cocoa/Cocoa.h>


@class TreeBalancer;
@class TreeContext;
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

- (TreeContext *) filterTree: (TreeContext *)oldTree;

- (void) abort;

@end
