#import <Cocoa/Cocoa.h>

#import "ScanTaskInput.h"

@protocol FileItemTest;


@interface RescanTaskInput : ScanTaskInput {
  NSObject <FileItemTest>  *filterTest;
}

- (id) initWithDirectoryName: (NSString *)name 
         fileSizeType: (int)fileSizeType
         filterTest: (NSObject <FileItemTest> *)test;

- (NSObject <FileItemTest> *) filterTest;

@end
