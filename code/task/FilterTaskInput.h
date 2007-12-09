#import <Cocoa/Cocoa.h>

@class TreeContext;
@protocol FileItemTest;


@interface FilterTaskInput : NSObject {
  TreeContext  *oldContext;
  NSObject <FileItemTest>  *filterTest;
}

- (id) initWithOldContext: (TreeContext *)context 
         filterTest: (NSObject <FileItemTest> *)test;

- (TreeContext *) oldContext;

- (NSObject <FileItemTest> *) filterTest;

@end
