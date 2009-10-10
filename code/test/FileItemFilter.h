#import <Cocoa/Cocoa.h>


@class FilterTest;
@class FileItemTestRepository;
@protocol FileItemTest;

/* A file item filter. It consists of one or more filter tests. The filter test
 * succeeds when any of its subtest succeed (i.e. the subtests are combined 
 * using the OR operator). Each filter subtest can optionally be inverted.
 *
 * The subtests are referenced by name, which means that changes to their
 * implementation after they have been added to the filter will affect the
 * implementation of the filter's overall test returned by 
 * -createFileItemTestFromRepository:.
 */
@interface FileItemFilter : NSObject {
  NSString  *name;
  
  // Array containing FilterTests
  NSMutableArray  *filterTests;
 
  /* The filter test. Only valid after -createFileItemTestFromRepository: has
   * been called.
   */
  NSObject <FileItemTest>  *fileItemTest;
}

- (id) init;
- (id) initWithName:(NSString *)name;

/* Initialises the filter based on the provided one. The newly created filter
 * will, however, not yet have an instantiated file item test. When the test is
 * (eventually) created using -createFileItemTestFromRepository:, it will be
 * based on the tests as then defined in the repository.
 */
- (id) initWithFileItemFilter:(FileItemFilter *)filter;


- (NSString *) name;
- (void) setName:(NSString *)name;

- (int) numFilterTests;
- (NSArray *) filterTests;
- (FilterTest *) filterTestAtIndex:(int) index;
- (FilterTest *) filterTestWithName:(NSString *)name;
- (int) indexOfFilterTest:(FilterTest *)test;

- (void) removeAllFilterTests;
- (void) removeFilterTestAtIndex:(int) index;
- (void) addFilterTest:(FilterTest *)test;

/* Creates the test object that represents the filter given the tests 
 * currently in the test repository. Returns the test that has been created,
 * which if it was non-nil can also be retrieved using -fileItemTest.
 */
- (NSObject <FileItemTest> *) createFileItemTestFromRepository: 
                                (FileItemTestRepository *)repository;

/* Creates the test object that represents the filter given the tests 
 * currently in the test repository. Returns the test that has been created,
 * which if it was non-nil can also be retrieved using -fileItemTest.
 *
 * If any test cannot be found in the repository its name will be added to
 * "unboundTests".
 */
- (NSObject <FileItemTest> *) createFileItemTestFromRepository: 
                                (FileItemTestRepository *)repository
                                unboundTests: (NSMutableArray *)unboundTests;

/* Can only be used after -createFileItemTestFromRepository: has been invoked
 * successfully.
 */
- (NSObject <FileItemTest> *)fileItemTest;

@end // @interface FileItemFilter


@interface FileItemFilter (ProtectedMethods)

/* Designated initialiser. It should not be called directly. Use the public
 * initialiser methods instead.
 */
- (id) initWithName:(NSString *)name filterTests:(NSArray *)filterTests;

@end // @interface FileItemFilter (ProtectedMethods)
