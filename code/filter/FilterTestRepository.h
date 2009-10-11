#import <Cocoa/Cocoa.h>

@class NotifyingDictionary;
@class FileItemTest;
@protocol StringTest;

@interface FilterTestRepository : NSObject {
  NotifyingDictionary  *testsByName;

  // Contains the tests provided by the application.
  NSDictionary  *applicationProvidedTests;
}

+ (FilterTestRepository *)defaultFilterTestRepository;

- (NotifyingDictionary *)testsByNameAsNotifyingDictionary;

- (FileItemTest *)fileItemTestForName:(NSString *)name;

- (FileItemTest *)applicationProvidedTestForName:(NSString *)name;

- (void) storeUserCreatedTests;

@end
