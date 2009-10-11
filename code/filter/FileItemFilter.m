#import "FileItemFilter.h"

#import "FileItemTest.h"
#import "FileItemTestRepository.h"
#import "FilterTestRef.h"

#import "CompoundOrItemTest.h"
#import "NotItemTest.h"


@implementation FileItemFilter

- (id) init {
  static int  nextFilterId = 1;

  NSString  *autoName = [NSString stringWithFormat: @"#%d", nextFilterId++];

  return [self initWithName: autoName
                 automaticName: YES
                 filterTests: [NSArray array]];
}

- (id) initWithName:(NSString *)nameVal {
  return [self initWithName: nameVal 
                 automaticName: NO 
                 filterTests: [NSArray array]];
}

- (id) initWithFileItemFilter:(FileItemFilter *)filter {
  return [self initWithName: [filter name] 
                 automaticName: [filter hasAutomaticName] 
                 filterTests: [filter filterTests]];
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
    
    hasAutomaticName = NO;
  }
}

- (BOOL) hasAutomaticName {
  return hasAutomaticName;
}

- (int) numFilterTests {
  return [filterTests count];
}

- (NSArray *) filterTests {
  return filterTests;
}

- (FilterTestRef *) filterTestAtIndex:(int) index {
  return [filterTests objectAtIndex: index];
}

- (FilterTestRef *) filterTestWithName:(NSString *)testName {
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

- (void) removeAllFilterTests {
  [filterTests removeAllObjects];
}

- (void) removeFilterTestAtIndex:(int) index {
  [filterTests removeObjectAtIndex: index];
}

- (void) addFilterTest:(FilterTestRef *)test {
  [filterTests addObject: test];
}


- (NSObject <FileItemTest> *) createFileItemTestFromRepository: 
                                (FileItemTestRepository *)repository {
  return [self createFileItemTestFromRepository: repository unboundTests: nil];
}

- (NSObject <FileItemTest> *) createFileItemTestFromRepository: 
                                (FileItemTestRepository *)repository
                                unboundTests: (NSMutableArray *)unboundTests {                                
  [fileItemTest release];
  fileItemTest = nil;

  NSMutableArray  *subTests = 
    [NSMutableArray arrayWithCapacity: [filterTests count]];

  NSEnumerator  *filterTestEnum = [filterTests objectEnumerator];
  FilterTestRef  *filterTest;

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

- (NSObject <FileItemTest> *)fileItemTest {
  return fileItemTest;
}

@end // @implementation FileItemFilter


@implementation FileItemFilter (ProtectedMethods)

/* Designated initialiser. It should not be called directly. Use the public
 * initialiser methods instead.
 */
- (id) initWithName:(NSString *)nameVal 
         automaticName:(BOOL) automaticName
         filterTests:(NSArray *)filterTestsVal {
  if (self = [super init]) {
    name = [nameVal retain];
    hasAutomaticName = automaticName;
    
    filterTests = [[NSMutableArray alloc] initWithCapacity: 8];
    [filterTests addObjectsFromArray: filterTestsVal];
    
    fileItemTest = nil;
  }

  return self;
}

@end // @implementation FileItemFilter (ProtectedMethods)
