#import "FileItemFilter.h"

#import "FileItemTest.h"
#import "FileItemTestRepository.h"
#import "FilterTest.h"

#import "CompoundOrItemTest.h"
#import "NotItemTest.h"


@implementation FileItemFilter

- (id) init {
  static int  nextFilterId = 1;

  NSString  *nameVal = [NSString stringWithFormat: @"#%d", nextFilterId++];
  return [self initWithName: nameVal];
}

- (id) initWithName:(NSString *)nameVal {
  return [self initWithName: nameVal filterTests: [NSArray array]];
}

- (id) initWithFileItemFilter:(FileItemFilter *)filter {
  return [self initWithName: [filter name] filterTests: [filter filterTests]];
}


- (void) dealloc {
  [name release];
  [filterTests release];
  [fileItemTest release];
  
  [super dealloc];
}


- (NSString *) name {
  return name;
}

- (void) setName:(NSString *)nameVal {
  if (name != nameVal) {
    [name release];
    name = [nameVal retain];
  }
}


- (int) numFilterTests {
  return [filterTests count];
}

- (NSArray *) filterTests {
  return filterTests;
}

- (FilterTest *) filterTestAtIndex:(int) index {
  return [filterTests objectAtIndex: index];
}

- (FilterTest *) filterTestWithName:(NSString *)testName {
  NSEnumerator  *filterTestEnum = [filterTests objectEnumerator];
  FilterTest  *filterTest;

  while (filterTest = [filterTestEnum nextObject]) {
    if ([[filterTest name] isEqualToString: testName]) {
      return filterTest;
    }
  }
  return nil;
}

- (int) indexOfFilterTest:(FilterTest *)test {
  return [filterTests indexOfObject: test];
}

- (void) removeAllFilterTests {
  [filterTests removeAllObjects];
}

- (void) removeFilterTestAtIndex:(int) index {
  [filterTests removeObjectAtIndex: index];
}

- (void) addFilterTest:(FilterTest *)test {
  [filterTests addObject: test];
}


- (NSObject <FileItemTest> *) createFileItemTestFromRepository: 
                                (FileItemTestRepository *)repository {
  [fileItemTest release];
  fileItemTest = nil;

  NSMutableArray  *subTests = 
    [NSMutableArray arrayWithCapacity: [filterTests count]];

  NSEnumerator  *filterTestEnum = [filterTests objectEnumerator];
  FilterTest  *filterTest;

  while (filterTest = [filterTestEnum nextObject]) {
    NSObject <FileItemTest>  *subTest = 
      [repository fileItemTestForName: [filterTest name]];

    if (subTest != nil) {
      if ([filterTest isInverted]) {
        subTest = 
          [[[NotItemTest alloc] initWithSubItemTest: subTest] autorelease];
      }
      
      [subTests addObject: subTest];
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

- (NSObject <FileItemTest> *)fileItemTest {
  return fileItemTest;
}

@end // @implementation FileItemFilter


@implementation FileItemFilter (ProtectedMethods)

/* Designated initialiser. It should not be called directly. Use the public
 * initialiser methods instead.
 */
- (id) initWithName:(NSString *)nameVal filterTests:(NSArray *)filterTestsVal {
  if (self = [super init]) {
    name = [nameVal retain];
    
    filterTests = [[NSMutableArray alloc] initWithCapacity: 8];
    [filterTests addObjectsFromArray: filterTestsVal];
    
    fileItemTest = nil;
  }

  return self;
}

@end // @implementation FileItemFilter (ProtectedMethods)
