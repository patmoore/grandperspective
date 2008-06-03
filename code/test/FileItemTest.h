#import <Cocoa/Cocoa.h>

@class FileItem;
@protocol FileItemTestVisitor;


#define TestResult  SInt8

#define TEST_PASSED          1
#define TEST_FAILED          0
#define TEST_NOT_APPLICABLE -1


// Instances implementing this protocol should be immutable. Their 
// configuration should remain fixed throughout their lifetime, but
// furthermore, they should not maintain any state (e.g. for performance
// optimalisation). The latter is forbidden, as the same test may be
// used in multiple threads concurrently.
@protocol FileItemTest

/* Tests the file item. It returns TEST_PASSED when the item passes the test, 
 * TEST_FAILED when the item fails the test, or TEST_NOT_APPLICABLE when the 
 * test does not apply to the item.
 *
 * A context is passed, which may provide additional information and/or
 * state used by the test. See the ItemPathTest class for an example.
 */
- (TestResult) testFileItem: (FileItem *)item context: (id)context;

- (NSString *) name;
- (void) setName: (NSString *)name;

/* Returns a dictionary that represents the test. It can be used for storing 
 * object to preferences.
 */
- (NSDictionary *) dictionaryForObject;

- (void) acceptFileItemTestVisitor: (NSObject <FileItemTestVisitor> *)visitor;

@end
