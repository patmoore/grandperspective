#import <Cocoa/Cocoa.h>

@class FileItemFilter;
@class FilterTestRepository;
@class FileItemTest;

/* Set of file item filters.
 */
@interface FileItemFilterSet : NSObject {
  // Array of FileItemFilters
  NSArray  *filters;
  
  FileItemTest  *fileItemTest;
}

+ (id) filterSet;
+ (id) filterSetWithFilter:(FileItemFilter *)filter;

/* Initialises an empty filter set.
 */
- (id) init;

/* Initialises the set to contain the given filter. The filter's test should
 * have been instantiated already.
 */
- (id) initWithFileItemFilter:(FileItemFilter *)filter;

/* Creates an updated set of filters. Each of the filters is re-instantiated
 * so that it is based on the tests currently defined in the test repository.
 */
- (FileItemFilterSet *)updatedFilterSetUsingRepository: 
                         (FilterTestRepository *)repository;

/* Creates an updated set of filters. Each of the filters is re-instantiated
 * so that it is based on the tests currently defined in the test repository.
 *
 * If any test cannot be found in the repository its name will be added to
 * "unboundTests".
 */
- (FileItemFilterSet *)updatedFilterSetUsingRepository: 
                         (FilterTestRepository *)repository
                         unboundTests: (NSMutableArray *)unboundTests;
                                
/* Creates a new set with an extra filter. The existing filters are taken
 * over directly (they are not re-instantiated).
 */
- (FileItemFilterSet *)filterSetWithNewFilter:(FileItemFilter *)filter;

- (int) numFileItemFilters;
- (NSArray *)fileItemFilters;

- (FileItemTest *)fileItemTest;

@end // @interface FileItemFilterSet


@interface FileItemFilterSet (ProtectedMethods)

/* Designated initialiser. It should not be called directly. Use the public
 * initialiser methods and factory methods instead.
 */
- (id) initWithFileItemFilters:(NSArray *)filters;

@end // @interface FileItemFilterSet (ProtectedMethods)
