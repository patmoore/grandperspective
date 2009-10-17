#import <Cocoa/Cocoa.h>


@class FilterTestRef;
@class FilterTestRepository;
@class FileItemTest;

/* A file item filter. It consists of one or more filter tests. The filter test
 * succeeds when any of its subtest succeed (i.e. the subtests are combined 
 * using the OR operator). Each filter subtest can optionally be inverted.
 *
 * The subtests are referenced by name, which means that changes to their
 * implementation after they have been added to the filter will affect the
 * implementation of the filter's overall test returned by 
 * -createFileItemTestFromRepository:. This method can be invoked multiple
 * times (and at any time) for a given filter, which means that its file item
 * test can change during its lifetime.
 */
@interface Filter : NSObject {
  NSString  *name;
  
  // Array containing FilterTestRefs
  NSMutableArray  *filterTests;
 
  /* The filter test. Only valid after -createFileItemTestFromRepository: has
   * been called.
   */
  FileItemTest  *fileItemTest;
}

+ (id) filter;
+ (id) filterWithName:(NSString *)name;
+ (id) filterWithFilterTests:(NSArray *)filterTests;
+ (id) filterWithName:(NSString *)name filterTests:(NSArray *)filterTests;
+ (id) filterWithFilter:(Filter *)filter;

/* Initialises an empty filter with an automatically generated name.
 */
- (id) init;

/* Initialises the filter with the given name.
 */
- (id) initWithName:(NSString *)name;

- (id) initWithFilterTests:(NSArray *)filterTests;

- (id) initWithName:(NSString *)name filterTests:(NSArray *)filterTests;

/* Initialises the filter based on the provided one. The newly created filter
 * will, however, not yet have an instantiated file item test. When the test is
 * (eventually) created using -createFileItemTestFromRepository:, it will be
 * based on the tests as then defined in the repository.
 */
- (id) initWithFilter:(Filter *)filter;


- (NSString *)name;
- (void) setName:(NSString *)name;

/* Returns YES if the name was automatically generated.
 */
- (BOOL) hasAutomaticName;

- (int) numFilterTests;
- (NSArray *)filterTests;
- (FilterTestRef *)filterTestAtIndex:(int) index;
- (FilterTestRef *)filterTestWithName:(NSString *)name;
- (int) indexOfFilterTest:(FilterTestRef *)test;

/* Creates the test object that represents the filter given the tests 
 * currently in the test repository. Returns the test that has been created,
 * which if it was non-nil can also be retrieved using -fileItemTest.
 */
- (FileItemTest *)createFileItemTestFromRepository: 
                    (FilterTestRepository *)repository;

/* Creates the test object that represents the filter given the tests 
 * currently in the test repository. Returns the test that has been created,
 * which if it was non-nil can also be retrieved using -fileItemTest.
 *
 * If any test cannot be found in the repository its name will be added to
 * "unboundTests".
 */
- (FileItemTest *) createFileItemTestFromRepository: 
                    (FilterTestRepository *)repository
                    unboundTests:(NSMutableArray *)unboundTests;

/* Can only be used after -createFileItemTestFromRepository: has been invoked
 * successfully.
 */
- (FileItemTest *)fileItemTest;

@end // @interface Filter
