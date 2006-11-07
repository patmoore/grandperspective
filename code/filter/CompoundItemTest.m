#import "CompoundItemTest.h"

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
