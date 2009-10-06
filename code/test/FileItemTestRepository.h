#import <Cocoa/Cocoa.h>

@class NotifyingDictionary;
@protocol FileItemTest;
@protocol StringTest;

@interface FileItemTestRepository : NSObject {
  NotifyingDictionary  *testsByName;

  // Contains the tests provided by the application.
  NSDictionary  *applicationProvidedTests;
}

+ (FileItemTestRepository*) defaultFileItemTestRepository;

- (NotifyingDictionary*) testsByNameAsNotifyingDictionary;

- (NSObject <FileItemTest> *) fileItemTestForName:(NSString *)name;

- (NSObject <FileItemTest> *) applicationProvidedTestForName: (NSString *)name;

- (void) storeUserCreatedTests;

+ (NSObject <FileItemTest> *) fileItemTestFromDictionary: (NSDictionary *)dict;
+ (NSObject <StringTest> *) stringTestFromDictionary: (NSDictionary *)dict;

@end
