#import "FileItemFilterSet.h"

#import "FileItemFilter.h"
#import "CompoundAndItemTest.h"

@interface FileItemFilterSet (PrivateMethods)

+ (id) filterSetWithFilters:(NSArray *)filters;

@end // @interface FileItemFilterSet (PrivateMethods)


@implementation FileItemFilterSet

+ (id) filterSet {
  return [[[FileItemFilterSet alloc] init] autorelease];
}

+ (id) filterSetWithFilter:(FileItemFilter *)filter {
  return [[[FileItemFilterSet alloc] initWithFileItemFilter: filter] 
              autorelease];
}


// Overrides designated initialiser.
- (id) init {
  return [self initWithFileItemFilters: [NSArray array]];
}

- (id) initWithFileItemFilter:(FileItemFilter *)filter {
  return [self initWithFileItemFilters: [NSArray arrayWithObject: filter]];
}

- (void) dealloc {
  [filters release];
  [fileItemTest release];
  
  [super dealloc];
}


- (FileItemFilterSet *)updatedFilterSetUsingRepository: 
                         (FileItemTestRepository *)repository {
  return [self updatedFilterSetUsingRepository: repository unboundTests: nil];
}

- (FileItemFilterSet *)updatedFilterSetUsingRepository: 
                         (FileItemTestRepository *)repository
                         unboundTests: (NSMutableArray *)unboundTests {
  NSMutableArray  *newFilters = 
    [NSMutableArray arrayWithCapacity: [filters count]];
  
  NSEnumerator  *filterEnum = [filters objectEnumerator];
  FileItemFilter  *filter;

  while (filter = [filterEnum nextObject]) {
    FileItemFilter  *updatedFilter = 
      [[[FileItemFilter alloc] initWithFileItemFilter: filter] autorelease];
       
    NSObject <FileItemTest>  *filterTest = 
      [updatedFilter createFileItemTestFromRepository: repository
                       unboundTests: unboundTests];
      
    if (filterTest != nil) {
      // Only add filters for which a tests still exists.
      
      [newFilters addObject: updatedFilter];
    }
    else {
      NSLog(@"Filter \"%@\" does not have a test anymore.", [filter name]);
    }
  }
  
  return [FileItemFilterSet filterSetWithFilters: newFilters];
}

- (FileItemFilterSet *)filterSetWithNewFilter:(FileItemFilter *)filter {
  NSMutableArray  *newFilters =
    [NSMutableArray arrayWithCapacity: [filters count]+1];
    
  [newFilters addObjectsFromArray: filters];
  [newFilters addObject: filter];
  
  return [FileItemFilterSet filterSetWithFilters: newFilters];
}

- (NSObject <FileItemTest> *)fileItemTest {
  return fileItemTest;
}


- (int) numFileItemFilters {
  return [filters count];
}

- (NSArray *)fileItemFilters {
  return [NSArray arrayWithArray: filters];
}


- (NSString *) description {
  NSMutableString  *descr = [NSMutableString stringWithCapacity: 32];
  
  NSEnumerator  *filterEnum = [filters objectEnumerator];
  FileItemFilter  *filter;

  while (filter = [filterEnum nextObject]) {
    // TODO: I18N?
    if ([descr length] > 0) {
      [descr appendString: @", "];
    }
    [descr appendString: [filter name]];
  }
  
  return descr;
}

@end // @implementation FileItemFilterSet


@implementation FileItemFilterSet (ProtectedMethods)

/* Designated initialiser.
 */
- (id) initWithFileItemFilters:(NSArray *)filtersVal {
  if (self = [super init]) {
    filters = [filtersVal retain];

    // Create the file item test for the set of filters.
    NSMutableArray  *filterTests = 
      [NSMutableArray arrayWithCapacity: [filters count]];
  
    NSEnumerator  *filterEnum = [filters objectEnumerator];
    FileItemFilter  *filter;

    while (filter = [filterEnum nextObject]) {
      NSObject <FileItemTest>  *filterTest = [filter fileItemTest];

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

@end // @implementation FileItemFilterSet (ProtectedMethods)


@implementation FileItemFilterSet (PrivateMethods)

+ (id) filterSetWithFilters:(NSArray *)filters {
  return [[[FileItemFilterSet alloc] initWithFileItemFilters:
              [NSArray arrayWithArray: filters]] autorelease];
}

@end // @implementation FileItemFilterSet (PrivateMethods)
