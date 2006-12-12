#import "CompoundItemTest.h"

#import "FileItemTestRepository.h"

@interface CompoundItemTest (PrivateMethods) 

/* Not implemented. Needs to be provided by subclass.
 *
 * It should return a template for describing a test consisting of two 
 * sub-tests. The string should have two "%@" arguments. The first for the
 * description of the first sub-test, and the second for the second sub-test.
 */
- (NSString*) bootstrapDescriptionTemplate;

/* Not implemented. Needs to be provided by subclass.
 *
 * It should return a template for describing a test consisting of three or
 * more sub-tests. The string should have two "%@" arguments. The first for the
 * description of the first sub-test, and the second for the description
 * of the remaining sub-tests. The template will be applied iteratively.
 */
- (NSString*) repeatingDescriptionTemplate;

@end // CompoundItemTest (PrivateMethods) 


@implementation CompoundItemTest

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithSubItemTests: instead.");
}

- (id) initWithSubItemTests:(NSArray*)subTestsVal {
  if (self = [super init]) {
    NSAssert([subTestsVal count] >= 2, 
             @"Compound test should have two or more sub-tests");
  
    // Make the array immutable
    subTests = [[NSArray alloc] initWithArray:subTestsVal];
  }
  
  return self;
}

- (void) dealloc {
  [subTests release];
  
  [super dealloc];
}


// Note: Special case. Does not call own designated initialiser. It should
// be overridden and only called by initialisers with the same signature.
- (id) initWithPropertiesFromDictionary: (NSDictionary *)dict {
  if (self = [super initWithPropertiesFromDictionary: dict]) {
    NSArray  *subTestDicts = [dict objectForKey: @"subTests"];
    
    NSMutableArray  *tmpSubTests = 
      [NSMutableArray arrayWithCapacity: [subTestDicts count]];
    NSEnumerator  *subTestsDictsEnum = [subTestDicts objectEnumerator];
    NSDictionary  *subTestDict;
    while ((subTestDict = [subTestsDictsEnum nextObject]) != nil) {
      [tmpSubTests addObject: 
        [FileItemTestRepository fileItemTestFromDictionary: subTestDict]];
    }
    
    // Make the array immutable
    subTests = [[NSArray alloc] initWithArray: tmpSubTests];
  }
  
  return self;
}

- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  NSMutableArray  *subTestsDicts = 
    [NSMutableArray arrayWithCapacity: [subTests count]];
  NSEnumerator  *subTestsEnum = [subTests objectEnumerator];
  NSObject <FileItemTest> *subTest;

  while ((subTest = [subTestsEnum nextObject]) != nil) {
    [subTestsDicts addObject: [subTest dictionaryForObject]];
  }

  [dict setObject: subTestsDicts forKey: @"subTests"];
}


- (NSArray*) subItemTests {
  return subTests;
}

- (BOOL) testFileItem:(FileItem*)item {
  NSAssert(NO, @"This method must be overridden.");
  return NO;
}


- (NSString*) description {
  NSEnumerator  *subTestEnum = [subTests reverseObjectEnumerator];

  // Can assume that there are always two sub-tests.
  NSString  *subTest = [subTestEnum nextObject]; // Last sub-test in array
  NSString  *descr =
    [NSString stringWithFormat: [self bootstrapDescriptionTemplate],
                                [subTestEnum nextObject], subTest];

  while ( subTest = [subTestEnum nextObject] ) {
    descr = [NSString stringWithFormat: [self repeatingDescriptionTemplate],
                                        subTest, descr];
  }
    
  return descr;
}

@end
