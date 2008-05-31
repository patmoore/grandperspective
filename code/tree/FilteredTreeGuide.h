#import <Cocoa/Cocoa.h>

#import "TreeTraverser.h"


@class FileItemPathStringCache;
@protocol FileItemTest;

/* Guide for traversing a tree when a filter is applied. It implements the
 * TreeTraverser protocol and only descends into items that pass the filter
 * test (or, more specifically, that do not fail it).
 */
@interface FilteredTreeGuide : NSObject <TreeTraverser> {

  NSObject <FileItemTest>  *itemTest;

  /* Cache used by filterTest.
   */
  FileItemPathStringCache  *fileItemPathStringCache;

  /* Controls if the filter should treat packages a plain files. When it is set
   * to YES, the filter is not applied to the package contents and the test for 
   * including the package itself will treat it as a file.
   */
  BOOL  packagesAsFiles;
  
  /* Used during recursion to track if the filter should be temporarily 
   * disabled. As long as the count is larger than zero, the filter is not 
   * applied. Descending into a package when packages should be treated as
   * files increases the count.
   */
  int  filterDisabledCount;
  
}

- (id) initWithFileItemTest:(NSObject <FileItemTest> *)itemTest
         packagesAsFiles: (BOOL) packagesAsFiles;

- (BOOL) packagesAsFiles;
- (NSObject <FileItemTest>*) fileItemTest;

@end
