#import <Cocoa/Cocoa.h>

@class NamedFilter;
@class FilterRepository;
@class FilterTestRepository;
@class FileItemTest;

/* Set of file item filters. The file item test representing the set of filters
 * is determined when the set is initialised and remains fixed. It is not
 * affected by changes to the file item tests of any of its filters.
 */
@interface FilterSet : NSObject {
  // Array of NamedFilters
  NSArray  *filters;
  
  FileItemTest  *fileItemTest;
}

+ (id) filterSet;
+ (id) filterSetWithNamedFilter:(NamedFilter *)filter;

/* Initialises an empty filter set.
 */
- (id) init;

/* Initialises the set to contain the given filter. The filter's test should
 * have been instantiated already.
 */
- (id) initWithNamedFilter:(NamedFilter *)filter;

/* Creates an updated set of filters. See 
 * updatedFilterSetUsingFilterRepository:testRepository:unboundFilters:unboundTests.
 */
- (FilterSet *)updatedFilterSetUnboundFilters:(NSMutableArray *)unboundFilters
                 unboundTests:(NSMutableArray *)unboundTests;
 
/* Creates an updated set of filters. See 
 * updatedFilterSetUsingFilterRepository:testRepository:unboundFilters:unboundTests.
 */
- (FilterSet *)updatedFilterSetUsingFilterRepository:
                   (FilterRepository *)filterRepository
                 testRepository:(FilterTestRepository *)testRepository;

/* Creates an updated set of filters. First, each filter is updated to its
 * current specification in the filter repository. If the filter, however, does
 * not exist anymore, its original definition is used. Subsequently, all filter
 * tests are re-instantiated so that it is based on the tests as they are
 * currently defined in the test repository.
 *
 * If any filter could not be found in the filter repository, its name will be
 * added to "unboundFilters".
 *
 * If any test cannot be found in the test repository its name will be added to
 * "unboundTests".
 */
- (FilterSet *)updatedFilterSetUsingFilterRepository:
                   (FilterRepository *)filterRepository
                 testRepository: (FilterTestRepository *)testRepository
                 unboundFilters:(NSMutableArray *)unboundFilters
                 unboundTests:(NSMutableArray *)unboundTests;
                                
/* Creates a new set with an extra filter. The existing filters are taken
 * over directly (they are not re-instantiated).
 */
- (FilterSet *)filterSetWithAddedNamedFilter:(NamedFilter *)filter;

- (int) numFilters;

/* Returns an array of NamedFilters.
 */
- (NSArray *)filters;

- (FileItemTest *)fileItemTest;

@end // @interface FilterSet


@interface FilterSet (ProtectedMethods)

/* Designated initialiser. It should not be called directly. Use the public
 * initialiser methods and factory methods instead.
 */
- (id) initWithNamedFilters:(NSArray *)filters;

@end // @interface FilterSet (ProtectedMethods)
