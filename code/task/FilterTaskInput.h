#import <Cocoa/Cocoa.h>

@class TreeContext;
@class FileItemFilterSet;


@interface FilterTaskInput : NSObject {
  BOOL  packagesAsFiles;
  TreeContext  *treeContext;
  FileItemFilterSet  *filterSet;
}

- (id) initWithTreeContext:(TreeContext *)context 
         filterSet:(FileItemFilterSet *)filterSet;

- (id) initWithTreeContext:(TreeContext *)context 
         filterSet:(FileItemFilterSet *)test
         packagesAsFiles:(BOOL) packagesAsFiles;


- (TreeContext *) treeContext;
- (FileItemFilterSet *) filterSet;
- (BOOL) packagesAsFiles;

@end
