#import <Cocoa/Cocoa.h>


@class FilteredTreeGuide;
@class TreeBalancer;
@class TreeContext;


@interface TreeFilter : NSObject {

  FilteredTreeGuide  *treeGuide;
  TreeBalancer  *treeBalancer;

  BOOL  abort;

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

@end
