#import <Cocoa/Cocoa.h>

@class DirectoryItem;
@protocol FileItemTest;


@interface FilterTaskInput : NSObject {
  DirectoryItem  *itemTree;
  NSObject <FileItemTest>  *filterTest;
}

- (id) initWithItemTree: (DirectoryItem *)tree 
         filterTest: (NSObject <FileItemTest> *)test;

- (DirectoryItem*) itemTree;

- (NSObject <FileItemTest> *) filterTest;

@end
