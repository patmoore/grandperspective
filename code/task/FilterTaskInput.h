#import <Cocoa/Cocoa.h>

@class TreeContext;
@class FilterSet;


@interface FilterTaskInput : NSObject {
  BOOL  packagesAsFiles;
  TreeContext  *treeContext;
  FilterSet  *filterSet;
}

- (id) initWithTreeContext:(TreeContext *)context 
         filterSet:(FilterSet *)filterSet;

- (id) initWithTreeContext:(TreeContext *)context 
         filterSet:(FilterSet *)test
         packagesAsFiles:(BOOL) packagesAsFiles;


- (TreeContext *) treeContext;
- (FilterSet *) filterSet;
- (BOOL) packagesAsFiles;

@end
