#import <Cocoa/Cocoa.h>


extern NSString  *NumFoldersProcessedKey;
extern NSString  *CurrentFolderPathKey;


@class FilteredTreeGuide;
@class TreeBalancer;
@class TreeContext;
@class DirectoryItem;


@interface TreeFilter : NSObject {

  FilteredTreeGuide  *treeGuide;
  TreeBalancer  *treeBalancer;

  BOOL  abort;
  
  // Lock protecting the progress statistics (which can be retrieved from a
  // thread different than the one building the tree).
  NSLock  *statsLock;
  
  // The number of folders that have been filtered so far.
  int  numFoldersProcessed;
   
  // The stack of directories that is currently being processed. The last
  // item is the directory that is currently being filtered.
  NSMutableArray  *directoryStack;

@private
  NSMutableArray*  tmpDirItems;
  NSMutableArray*  tmpFileItems;
}


- (id) initWithFilteredTreeGuide: (FilteredTreeGuide *)treeGuide;

/* Filters the tree. Omits all items from the old tree that should not be
 * descended into according to the filtered tree guide.
 */
- (TreeContext *) filterTree: (TreeContext *)oldTree;

/* Aborts filtering (when it is carried out in a different execution thread). 
 */
- (void) abort;

/* Returns a dictionary containing information about the progress of the
 * ongoing tree-filtering task.
 *
 * It can safely be invoked from a different thread than the one that invoked
 * -filterTree: (and not doing so would actually be quite silly).
 */
- (NSDictionary *) treeFilterProgressInfo;

@end
