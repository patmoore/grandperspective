#import <Cocoa/Cocoa.h>

@class NamedFilter;
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

/* Creates an updated set of filters. Each of the filters is re-instantiated
 * so that it is based on the tests currently defined in the test repository.
 */
- (FilterSet *)updatedFilterSetUsingRepository: 
                 (FilterTestRepository *)repository;

/* Creates an updated set of filters. Each of the filters is re-instantiated
 * so that it is based on the tests currently defined in the test repository.
 *
 * If any test cannot be found in the repository its name will be added to
 * "unboundTests".
 */
- (FilterSet *)updatedFilterSetUsingRepository: 
                 (FilterTestRepository *)repository
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
