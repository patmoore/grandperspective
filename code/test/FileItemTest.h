#import <Cocoa/Cocoa.h>

@class FileItem;
@protocol FileItemTestVisitor;


#define TestResult  SInt8

/* TestResult values
 */
#define TEST_PASSED          1
#define TEST_FAILED          0
#define TEST_NOT_APPLICABLE -1


/* (Abstract) test that can be applied to a FileItem. 
 *
 * Instances should be immutable. Their configuration should remain fixed
 * throughout their lifetime, but furthermore, they should not maintain any
 * state (e.g. for performance optimalisation). The latter is forbidden, as 
 * the same test may be used in multiple threads concurrently.
 */
@interface FileItemTest : NSObject {
}

+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict;

/* Returns a dictionary that represents the test. It can be used for storing 
 * object to preferences.
 */
- (NSDictionary *)dictionaryForObject;

@end // @interface FileItemTest


@interface FileItemTest (AbstractMethods)

/* Tests the file item. It returns TEST_PASSED when the item passes the test, 
 * TEST_FAILED when the item fails the test, or TEST_NOT_APPLICABLE when the 
 * test does not apply to the item.
 *
 * A context is passed, which may provide additional information and/or
 * state used by the test. See the ItemPathTest class for an example.
 */
- (TestResult) testFileItem:(FileItem *)item context:(id) context;

/* Returns YES iff the test applies (also) to directories. Returns NO 
 * otherwise, i.e. when the test only applies to files and returns
 * TEST_NOT_APPLICABLE for directory items.
 */
- (BOOL) appliesToDirectories;

- (void) acceptFileItemTestVisitor:(NSObject <FileItemTestVisitor> *)visitor;

@end // @interface FileItemTest (AbstractMethods)

@interface FileItemTest (ProtectedMethods)

// Helper methods for storing and restoring objects from preferences. These
// are meant to be used and overridden by subclasses, and should not be 
// called directly.
- (id) initWithPropertiesFromDictionary: (NSDictionary *)dict;
- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict;

@end // @interface FileItemTest (ProtectedMethods)
