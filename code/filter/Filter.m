#import "Filter.h"

#import "FileItemTest.h"
#import "FilterTestRepository.h"
#import "FilterTestRef.h"

#import "CompoundOrItemTest.h"
#import "NotItemTest.h"


@implementation Filter

+ (id) filter {
  return [[[Filter alloc] init] autorelease];
}

+ (id) filterWithName:(NSString *)name {
  return [[[Filter alloc] initWithName: name] autorelease];
}

+ (id) filterWithFilterTests:(NSArray *)filterTests {
  return [[[Filter alloc] initWithFilterTests: filterTests] autorelease];
}

+ (id) filterWithName:(NSString *)name filterTests:(NSArray *)filterTests {
  return [[[Filter alloc] initWithName: name filterTests: filterTests] 
              autorelease];
}

+ (id) filterWithFilter:(Filter *)filter {
  return [[[Filter alloc] initWithFilter: filter] autorelease];
}


+ (Filter *)filterFromDictionary:(NSDictionary *)dict {
  NSArray  *storedFilterTests = [dict objectForKey: @"tests"];
  NSMutableArray  *testRefs = 
    [NSMutableArray arrayWithCapacity: [storedFilterTests count]];
    
  NSEnumerator  *testEnum = [storedFilterTests objectEnumerator];
  NSDictionary  *storedFilterTest;
  while (storedFilterTest = [testEnum nextObject]) {
    FilterTestRef  *testRef = 
      [FilterTestRef filterTestRefFromDictionary: storedFilterTest];
    [testRefs addObject: testRef];
  }
  
  // TODO: Remove. Don't include name in basic filter object. Maybe add a
  // NamedFilter wrapper instead.
  NSString  *name = [dict objectForKey: @"name"];

  return [Filter filterWithName: name filterTests: testRefs];
}


- (id) init {
  return [self initWithName: nil filterTests: [NSArray array]];
}

- (id) initWithName:(NSString *)nameVal {
  return [self initWithName: nameVal filterTests: [NSArray array]];
}

- (id) initWithFilterTests:(NSArray *)filterTestsVal {
  return [self initWithName: nil filterTests: filterTestsVal];
}

- (id) initWithFilter:(Filter *)filter {
  return [self initWithName: [filter name] filterTests: [filter filterTests]];
}

- (id) initWithName:(NSString *)nameVal 
         filterTests:(NSArray *)filterTestsVal {
  static int  nextFilterId = 1;

  if (self = [super init]) {
    if (nameVal == nil) {
      nameVal = [NSString stringWithFormat: @"#%d", nextFilterId++];
    }
  
    name = [nameVal retain];
    
    filterTests = [[NSArray alloc] initWithArray: filterTestsVal];    
    fileItemTest = nil;
  }

  return self;
}


- (void) dealloc {
  [name release];
  [filterTests release];
  [fileItemTest release];
  
  [super dealloc];
}


- (NSString *)name {
  return name;
}

- (void) setName:(NSString *)nameVal {
  if (name != nameVal) {
    [name release];
    name = [nameVal retain];
  }
}

- (BOOL) hasAutomaticName {
  return [name hasPrefix: @"#"];
}

- (int) numFilterTests {
  return [filterTests count];
}

- (NSArray *)filterTests {
  return filterTests;
}

- (FilterTestRef *)filterTestAtIndex:(int) index {
  return [filterTests objectAtIndex: index];
}

- (FilterTestRef *)filterTestWithName:(NSString *)testName {
  NSEnumerator  *filterTestEnum = [filterTests objectEnumerator];
  FilterTestRef  *filterTest;

  while (filterTest = [filterTestEnum nextObject]) {
    if ([[filterTest name] isEqualToString: testName]) {
      return filterTest;
    }
  }
  return nil;
}

- (int) indexOfFilterTest:(FilterTestRef *)test {
  return [filterTests indexOfObject: test];
}


- (FileItemTest *)createFileItemTestFromRepository: 
                    (FilterTestRepository *)repository {
  return [self createFileItemTestFromRepository: repository unboundTests: nil];
}

- (FileItemTest *)createFileItemTestFromRepository: 
                    (FilterTestRepository *)repository
                    unboundTests:(NSMutableArray *)unboundTests {
  NSAssert(fileItemTest == nil, @"File item test already set.");

  NSMutableArray  *subTests = 
    [NSMutableArray arrayWithCapacity: [filterTests count]];

  NSEnumerator  *filterTestEnum = [filterTests objectEnumerator];
  FilterTestRef  *filterTest;

  while (filterTest = [filterTestEnum nextObject]) {
    FileItemTest  *subTest = 
      [repository fileItemTestForName: [filterTest name]];

    if (subTest != nil) {
      if ([filterTest isInverted]) {
        subTest = 
          [[[NotItemTest alloc] initWithSubItemTest: subTest] autorelease];
      }
      
      [subTests addObject: subTest];
    }
    else {
      [unboundTests addObject: [filterTest name]];
    }
  }
  
  if ([subTests count] == 0) {
    fileItemTest = nil;
  }
  else if ([subTests count] == 1) {
    fileItemTest = [[subTests objectAtIndex: 0] retain];
  }
  else {
    fileItemTest = [[CompoundOrItemTest alloc] initWithSubItemTests: subTests];
  }
  
  return fileItemTest;
}

- (FileItemTest *)fileItemTest {
  return fileItemTest;
}

- (NSDictionary *)dictionaryForObject {
  NSMutableArray  *storedTests = 
    [NSMutableArray arrayWithCapacity: [filterTests count]];
  NSEnumerator  *testEnum = [filterTests objectEnumerator];
  FilterTestRef  *testRef;
  while (testRef = [testEnum nextObject]) {
    [storedTests addObject: [testRef dictionaryForObject]];
  }
  
  return [NSDictionary dictionaryWithObjectsAndKeys:
                         name, @"name",
                         storedTests, @"tests",
                         nil];
}

@end // @implementation Filter
