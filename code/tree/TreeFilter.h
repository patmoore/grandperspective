#import <Cocoa/Cocoa.h>


@class TreeBalancer;
@class TreeContext;
@class FileItemPathStringCache;
@protocol FileItemTest;


@interface TreeFilter : NSObject {

  TreeBalancer  *treeBalancer;
  NSObject <FileItemTest>  *itemTest;

  /* Controls if the filter should treat packages a plain files. When it is set
   * to YES, the filter is not applied to the package contents and the test for 
   * including the package itself will treat it as a file.
   */
  BOOL  packagesAsFiles;

  FileItemPathStringCache  *fileItemPathStringCache;

  BOOL  abort;
  
  /* Used during recursion to track if the filter should be temporarily 
   * disabled. As long as the count is larger than zero, the filter is not 
   * applied. Descending into a package when packages should be treated as
   * files increases the count.
   */
  int  filterDisabledCount;
  
@private
  NSMutableArray*  tmpDirItems;
  NSMutableArray*  tmpFileItems;
}


- (id) initWithFileItemTest:(NSObject <FileItemTest> *)itemTest
         packagesAsFiles: (BOOL) packagesAsFiles;


- (TreeContext *) filterTree: (TreeContext *)oldTree;

- (void) abort;

@end
