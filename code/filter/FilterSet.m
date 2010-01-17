#import "FilterSet.h"

#import "Filter.h"
#import "NamedFilter.h"
#import "CompoundAndItemTest.h"

#import "FilterRepository.h"
#import "FilterTestRepository.h"

@interface FilterSet (PrivateMethods)

+ (id) filterSetWithNamedFilters:(NSArray *)filters;

@end // @interface FilterSet (PrivateMethods)


@implementation FilterSet

+ (id) filterSet {
  return [[[FilterSet alloc] init] autorelease];
}

+ (id) filterSetWithNamedFilter:(NamedFilter *)filter {
  return [[[FilterSet alloc] initWithNamedFilter: filter] autorelease];
}


// Overrides designated initialiser.
- (id) init {
  return [self initWithNamedFilters: [NSArray array]];
}

- (id) initWithNamedFilter:(NamedFilter *)filter {
  return [self initWithNamedFilters: [NSArray arrayWithObject: filter]];
}

- (void) dealloc {
  [filters release];
  [fileItemTest release];
  
  [super dealloc];
}


- (FilterSet *)updatedFilterSetUnboundFilters:(NSMutableArray *)unboundFilters
                 unboundTests:(NSMutableArray *)unboundTests {
  return [self updatedFilterSetUsingFilterRepository: 
                   [FilterRepository defaultInstance]
                  testRepository: [FilterTestRepository defaultInstance]
                  unboundFilters: unboundFilters
                  unboundTests: unboundTests];
}

- (FilterSet *)updatedFilterSetUsingFilterRepository:
                   (FilterRepository *)filterRepository
                 testRepository:(FilterTestRepository *)testRepository {
  return [self updatedFilterSetUsingFilterRepository: filterRepository 
                 testRepository: testRepository
                 unboundFilters: nil
                 unboundTests: nil];
}

- (FilterSet *)updatedFilterSetUsingFilterRepository:
                   (FilterRepository *)filterRepository
                 testRepository:(FilterTestRepository *)testRepository
                 unboundFilters:(NSMutableArray *)unboundFilters
                 unboundTests:(NSMutableArray *)unboundTests {
  NSMutableArray  *newFilters = 
    [NSMutableArray arrayWithCapacity: [filters count]];
  
  NSEnumerator  *filterEnum = [filters objectEnumerator];
  NamedFilter  *namedFilter;

  while (namedFilter = [filterEnum nextObject]) {
    Filter  *filter =
      [[filterRepository filtersByName] objectForKey: [namedFilter name]];
    if (filter == nil) {
      // The filter with this name does not exist anymore in the repository.
      [unboundFilters addObject: [namedFilter name]];

      // Use the original filter.
      filter = [namedFilter filter];
    }
    
    Filter  *newFilter = [Filter filterWithFilter: filter];       
    FileItemTest  *filterTest = 
      [newFilter createFileItemTestFromRepository: testRepository
                   unboundTests: unboundTests];
      
    if (filterTest != nil) {
      // Only add filters for which a tests still exists.
      
      NamedFilter  *newNamedFilter = 
        [NamedFilter namedFilter: newFilter name: [namedFilter name]];
      [newFilters addObject: newNamedFilter];
    }
    else {
      NSLog(@"Filter \"%@\" does not have a test anymore.", 
                [namedFilter name]);
    }
  }
  
  return [FilterSet filterSetWithNamedFilters: newFilters];
}

- (FilterSet *)filterSetWithAddedNamedFilter:(NamedFilter *)filter {
  NSMutableArray  *newFilters =
    [NSMutableArray arrayWithCapacity: [filters count]+1];
    
  [newFilters addObjectsFromArray: filters];
  [newFilters addObject: filter];
  
  return [FilterSet filterSetWithNamedFilters: newFilters];
}

- (FileItemTest *)fileItemTest {
  return fileItemTest;
}


- (int) numFilters {
  return [filters count];
}

- (NSArray *)filters {
  return [NSArray arrayWithArray: filters];
}


- (NSString *)description {
  NSMutableString  *descr = [NSMutableString stringWithCapacity: 32];
  
  NSEnumerator  *filterEnum = [filters objectEnumerator];
  NamedFilter  *namedFilter;

  while (namedFilter = [filterEnum nextObject]) {
    if ([descr length] > 0) {
      [descr appendString: @", "];
    }
    [descr appendString: [namedFilter localizedName]];
  }
  
  return descr;
}

@end // @implementation FilterSet


@implementation FilterSet (ProtectedMethods)

/* Designated initialiser.
 */
- (id) initWithNamedFilters:(NSArray *)filtersVal {
  if (self = [super init]) {
    filters = [filtersVal retain];

    // Create the file item test for the set of filters.
    NSMutableArray  *filterTests = 
      [NSMutableArray arrayWithCapacity: [filters count]];
  
    NSEnumerator  *filterEnum = [filters objectEnumerator];
    NamedFilter  *namedFilter;
    while (namedFilter = [filterEnum nextObject]) {
      Filter  *filter = [namedFilter filter];
      FileItemTest  *filterTest = [filter fileItemTest];

      NSAssert(filterTest != nil, @"Filter not instantiated.");
      [filterTests addObject: filterTest];
    }

    if ([filterTests count] == 0) {
      fileItemTest = nil;
    }
    else if ([filterTests count] == 1) {
      fileItemTest = [[filterTests objectAtIndex: 0] retain];
    }
    else {
      fileItemTest =
        [[CompoundAndItemTest alloc] initWithSubItemTests: filterTests];
    }
  }
  return self;
}

@end // @implementation FilterSet (ProtectedMethods)


@implementation FilterSet (PrivateMethods)

+ (id) filterSetWithNamedFilters:(NSArray *)filters {
  return [[[FilterSet alloc] initWithNamedFilters:
              [NSArray arrayWithArray: filters]] autorelease];
}

@end // @implementation FilterSet (PrivateMethods)
