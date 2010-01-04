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

+ (id) filterWithFilterTests:(NSArray *)filterTests {
  return [[[Filter alloc] initWithFilterTests: filterTests] autorelease];
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
  
  return [Filter filterWithFilterTests: testRefs];
}


- (id) init {
  return [self initWithFilterTests: [NSArray array]];
}

- (id) initWithFilter:(Filter *)filter {
  return [self initWithFilterTests: [filter filterTests]];
}

- (id) initWithFilterTests:(NSArray *)filterTestsVal {
  if (self = [super init]) {
    filterTests = [[NSArray alloc] initWithArray: filterTestsVal];    
    fileItemTest = nil;
  }

  return self;
}


- (void) dealloc {
  [filterTests release];
  [fileItemTest release];
  
  [super dealloc];
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
                         storedTests, @"tests",
                         nil];
}

@end // @implementation Filter
