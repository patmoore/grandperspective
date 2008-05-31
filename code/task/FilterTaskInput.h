#import <Cocoa/Cocoa.h>

@class TreeContext;
@protocol FileItemTest;


@interface FilterTaskInput : NSObject {
  BOOL  packagesAsFiles;
  TreeContext  *oldContext;
  NSObject <FileItemTest>  *filterTest;
}

- (id) initWithOldContext: (TreeContext *)context 
         filterTest: (NSObject <FileItemTest> *)test;

- (id) initWithOldContext: (TreeContext *)context 
         filterTest: (NSObject <FileItemTest> *)test
         packagesAsFiles: (BOOL) packagesAsFiles;


- (TreeContext *) oldContext;
- (NSObject <FileItemTest> *) filterTest;
- (BOOL) packagesAsFiles;

@end
