#import <Cocoa/Cocoa.h>

@class TreeHistory;
@protocol FileItemTest;


@interface FilterTaskInput : NSObject {
  TreeHistory  *oldHistory;
  NSObject <FileItemTest>  *filterTest;
}

- (id) initWithOldHistory: (TreeHistory *)history 
         filterTest: (NSObject <FileItemTest> *)test;

- (TreeHistory *) oldHistory;

- (NSObject <FileItemTest> *) filterTest;

@end
