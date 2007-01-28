#import <Cocoa/Cocoa.h>

#import "ScanTaskInput.h"

@protocol FileItemTest;


@interface RescanTaskInput : ScanTaskInput {
  NSObject <FileItemTest>  *filterTest;
}

- (id) initWithDirectoryName: (NSString *)name 
         fileSizeType: (NSString *)type
         filterTest: (NSObject <FileItemTest> *)test;

- (NSObject <FileItemTest> *) filterTest;

@end
