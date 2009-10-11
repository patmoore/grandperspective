#import <Cocoa/Cocoa.h>

@class FileItem;
@class DirectoryItem;
@class FileItemPathStringCache;
@class FileItemTest;

/* Guide for traversing a tree when a filter is applied. It can be used when
 * the tree is complete, as well as when the tree is still being constructed.
 *
 * When the tree is complete, the usage of the guide is as follows:
 *
 * FileItem  *fileItemToUse = [guide includeFileItem: fileItem];
 *
 * if  (fileItemToUse != nil) {               // The file item passed the test
 *   // Handle file item
 * 
 *   if ([fileItemToUse isDirectory]) {
 *     [guide descendIntoDirectory: (DirectoryItem *)fileItemToUse];
 *
 *     // Recurse over dir contents 
 *
 *     [guide emergedFromDirectory: (DirectoryItem *)fileItemToUse];
 *   }
 * }
 *
 * On the other hand, when the tree is being constructed, the guide should be
 * used as follows:
 *
 * if ( [fileItem isDirectory] 
 *      && [guide shouldDescendIntoDirectory: (DirectoryItem *)fileItem]) {
 *   [guide descendIntoDirectory: (DirectoryItem *)fileItem];
 * 
 *   // Recurse to set directory contents
 *
 *   [guide emergedFromDirectory: (DirectoryItem *)fileItem];
 * }
 *
 * if ( [guide includeFileItem: fileItem] != nil ) {
 *   // Add the item to the tree
 * }
 */
@interface FilteredTreeGuide : NSObject {

  FileItemTest  *itemTest;

  /* Cache used by filterTest.
   */
  FileItemPathStringCache  *fileItemPathStringCache;

  /* Controls if the filter should treat packages a plain files. When it is set
   * to YES, the filter is not applied to the package contents and the test for 
   * including the package itself will treat it as a file.
   */
  BOOL  packagesAsFiles;
  
  /* Set to YES iff "itemTest" includes an ItemSizeTest. If this is the case,
   * and packages are to be treated as files, the contents of the directory
   * need to be set before the test can be applied.
   */
  BOOL  testUsesSize;
  
  /* Tracks the number of packages that have been recursively descended into
   * (and not yet emerged from). It is used to determine if the filter should 
   * be temporarily disabled when packages are treated as files.
   */
  int  packageCount;
  
}

- (id) initWithFileItemTest:(FileItemTest *)itemTest;
- (id) initWithFileItemTest:(FileItemTest *)itemTest
         packagesAsFiles:(BOOL) packagesAsFiles;


- (BOOL) packagesAsFiles;
- (void) setPackagesAsFiles: (BOOL) flag;

- (FileItemTest *)fileItemTest;
- (void) setFileItemTest:(FileItemTest *)test;


/* Returns "nil" iff the file item should be ignored (because it did not pass
 * the filter test). 
 *
 * For completed trees, this method should be called before possibly descending 
 * into it. The return value is the item that should be used (it may be the 
 * supplied item, but in case of a DirectoryItem that is a package, it can be a 
 * FileItem that represent the package as a file). 
 *
 * For trees that are being constructed, this method should only be invoked
 * after descending into the item if need be (as indicated by 
 * -shouldDescendIntoDirectory:). In this case, a check for a non-nil return
 * value is sufficient. The actual item to add to the tree can be the original
 * one, as opposed to the returned one (this way, the constructed tree can be
 * used with or without package contents being shown, irrespective of the
 * configuration of the current guide).
 */
- (FileItem *)includeFileItem:(FileItem *)item;

/* Returns YES if the item should be visited. It should only be used when the
 * tree is being constructed. In this case, for certain directories it is clear
 * that they should be excluded before constructing them, for others (in 
 * particular packages, when packages are treated as files) this may not be 
 * the case, and its contents should be set first. Subsequently, a call to
 * -includeFileItem may still return NO, indicating that the item should be
 * excluded from the tree. 
 */
- (BOOL) shouldDescendIntoDirectory:(DirectoryItem *)item;

/* Called to indicate that the given item is being visited. This should only
 * be done for directories for which an earlier call to either -includeFileItem
 * (when a complete tree is traversed) or -shouldDescendInfoFileItem:
 * (when the tree is being  constructed) returned YES.
 */
- (void) descendIntoDirectory:(DirectoryItem *)item;

/* Called to indicate that the item has been visited.
 */
- (void) emergedFromDirectory:(DirectoryItem *)item;

@end
