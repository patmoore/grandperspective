#import <Cocoa/Cocoa.h>


@class FilterSet;
@class FilteredTreeGuide;
@class TreeBalancer;
@class TreeContext;
@class DirectoryItem;
@class ProgressTracker;


@interface TreeFilter : NSObject {

  FilterSet  *filterSet;

  FilteredTreeGuide  *treeGuide;
  TreeBalancer  *treeBalancer;

  BOOL  abort;
  
  ProgressTracker  *progressTracker;
  
@private
  NSMutableArray*  tmpDirItems;
  NSMutableArray*  tmpFileItems;
}


- (id) initWithFilterSet:(FilterSet *)filterSet;

- (BOOL) packagesAsFiles;
- (void) setPackagesAsFiles: (BOOL) flag;


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
- (NSDictionary *) progressInfo;

@end
