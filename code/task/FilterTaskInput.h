#import <Cocoa/Cocoa.h>

@class TreeContext;
@protocol FileItemTest;


@interface FilterTaskInput : NSObject {
  BOOL  packagesAsFiles;
  TreeContext  *treeContext;
  NSObject <FileItemTest>  *filterTest;
}

- (id) initWithTreeContext: (TreeContext *)context 
         filterTest: (NSObject <FileItemTest> *)test;

- (id) initWithTreeContext: (TreeContext *)context 
         filterTest: (NSObject <FileItemTest> *)test
         packagesAsFiles: (BOOL) packagesAsFiles;


- (TreeContext *) treeContext;
- (NSObject <FileItemTest> *) filterTest;
- (BOOL) packagesAsFiles;

@end
