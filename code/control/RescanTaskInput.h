#import <Cocoa/Cocoa.h>

@protocol FileItemTest;


@interface RescanTaskInput : NSObject {
  NSString  *dirName;
  NSObject <FileItemTest>  *filterTest;
}

- (id) initWithDirectoryName: (NSString *)name 
         filterTest: (NSObject <FileItemTest> *)test;

- (NSString*) directoryName;

- (NSObject <FileItemTest> *) filterTest;

@end
