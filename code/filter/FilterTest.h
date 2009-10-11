#import <Cocoa/Cocoa.h>


@protocol FileItemTest;

@interface FilterTest : NSObject {
  NSString  *name;
  NSObject <FileItemTest>  *test;
}

+ (id) filterTestWithName: (NSString *)name 
         fileItemTest: (NSObject <FileItemTest> *)test;

- (id) initWithName: (NSString *)name 
         fileItemTest: (NSObject <FileItemTest> *)test;

- (NSString *)name;

- (NSObject <FileItemTest> *)fileItemTest;

@end
