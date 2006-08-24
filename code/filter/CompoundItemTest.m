#import "CompoundItemTest.h"

@interface CompoundItemTest (PrivateMethods) 

// Not implemented. Needs to be provided by subclass.
//
// It should return a string with two "%@" arguments. The first for the
// description of the first sub-test, and the second for the description
// of the remaining sub-tests. The template will be applied iteratively.
- (NSString*) descriptionTemplate;

@end // CompoundItemTest (PrivateMethods) 


@implementation CompoundItemTest

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithSubItemTests: instead.");
}

- (id) initWithSubItemTests:(NSArray*)subTestsVal {
  if (self = [super init]) {
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
  NSString  *template = [self descriptionTemplate];
  NSString  *descr = @"";

  int  i = 0;
  int  max = [subTests count];
    
  while (i < max) {
    NSString  *subTestDescr = [[subTests objectAtIndex:i++] description];

    if ([subTestDescr length] > 0) {
      descr = ( ([descr length] == 0) 
                ? subTestDescr 
                : [NSString stringWithFormat: template, subTestDescr, descr] );
    }
  }
    
  return descr;
}

@end
