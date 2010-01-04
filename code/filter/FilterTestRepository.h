#import <Cocoa/Cocoa.h>

@class NotifyingDictionary;
@class FileItemTest;

@interface FilterTestRepository : NSObject {
  NotifyingDictionary  *testsByName;

  // Contains the tests provided by the application.
  NSDictionary  *applicationProvidedTests;
}

+ (FilterTestRepository *)defaultFilterTestRepository;

/* Returns the tests in a dictionary that can subsequently be modified.
 */
- (NotifyingDictionary *)testsByNameAsNotifyingDictionary;

/* Returns dictionary as an NSDictionary, which is useful if the dictionary
 * does not need to be modified. Note, the dictionary can still be modified
 * by casting it to NotifyingDictionary. This is only a convenience method.
 */
- (NSDictionary *)testsByName;

- (FileItemTest *)fileItemTestForName:(NSString *)name;

- (FileItemTest *)applicationProvidedTestForName:(NSString *)name;

- (void) storeUserCreatedTests;

@end
