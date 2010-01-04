#import "FilterSet.h"

#import "Filter.h"
#import "NamedFilter.h"
#import "CompoundAndItemTest.h"

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


- (FilterSet *)updatedFilterSetUsingRepository: 
                 (FilterTestRepository *)repository {
  return [self updatedFilterSetUsingRepository: repository unboundTests: nil];
}

- (FilterSet *)updatedFilterSetUsingRepository: 
                 (FilterTestRepository *)repository
                 unboundTests:(NSMutableArray *)unboundTests {
  NSMutableArray  *newFilters = 
    [NSMutableArray arrayWithCapacity: [filters count]];
  
  NSEnumerator  *filterEnum = [filters objectEnumerator];
  NamedFilter  *namedFilter;

  while (namedFilter = [filterEnum nextObject]) {
    Filter  *filter = [namedFilter filter];
    Filter  *newFilter = [Filter filterWithFilter: filter];
       
    FileItemTest  *filterTest = 
      [newFilter createFileItemTestFromRepository: repository
                   unboundTests: unboundTests];
      
    if (filterTest != nil) {
      // Only add filters for which a tests still exists.
      
      NamedFilter  *newNamedFilter = 
        [NamedFilter namedFilter: filter name: [namedFilter name]];
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
    // TODO: I18N?
    if ([descr length] > 0) {
      [descr appendString: @", "];
    }
    [descr appendString: [namedFilter name]];
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
