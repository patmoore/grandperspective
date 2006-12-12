#import <Cocoa/Cocoa.h>

@class NotifyingDictionary;
@protocol FileItemTest;
@protocol StringTest;

@interface FileItemTestRepository : NSObject {
  NotifyingDictionary  *testsByName;

  // Contains the default tests, as initially created.
  NSDictionary  *defaultTests;
}

+ (FileItemTestRepository*) defaultFileItemTestRepository;

- (NotifyingDictionary*) testsByNameAsNotifyingDictionary;

- (void) storeUserCreatedTestsInUserDefaults;

+ (NSObject <FileItemTest> *) fileItemTestFromDictionary: (NSDictionary *)dict;
+ (NSObject <StringTest> *) stringTestFromDictionary: (NSDictionary *)dict;

@end
