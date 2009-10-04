#import "NotItemTest.h"

#import "FileItemTestVisitor.h"
#import "FileItemTestRepository.h"


@implementation NotItemTest

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithSubItemTest: instead.");
}

- (id) initWithSubItemTest: (NSObject<FileItemTest> *)subTestVal {
  if (self = [super init]) {
    subTest = [subTestVal retain];
  }

  return self;
}

- (void) dealloc {
  [subTest release];
  
  [super dealloc];
}


// Note: Special case. Does not call own designated initialiser. It should
// be overridden and only called by initialisers with the same signature.
- (id) initWithPropertiesFromDictionary: (NSDictionary *)dict {
  if (self = [super initWithPropertiesFromDictionary: dict]) {
    NSDictionary  *subTestDict = [dict objectForKey: @"subTest"];
    
    subTest = 
      [[FileItemTestRepository fileItemTestFromDictionary: subTestDict]
          retain];
  }
  
  return self;
}

- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  [dict setObject: @"NotItemTest" forKey: @"class"];

  [dict setObject: [subTest dictionaryForObject] forKey: @"subTest"];
}


- (NSObject <FileItemTest> *) subItemTest {
  return subTest;
}


- (TestResult) testFileItem: (FileItem *)item context: (id)context {
  TestResult  result = [subTest testFileItem: item context: context];
  
  return ( (result == TEST_NOT_APPLICABLE) 
           ? TEST_NOT_APPLICABLE
           : ( (result == TEST_FAILED) ? TEST_PASSED : TEST_FAILED ) );
}

- (BOOL) appliesToDirectories {
  return [subTest appliesToDirectories];
}

- (void) acceptFileItemTestVisitor: (NSObject <FileItemTestVisitor> *)visitor {
  [visitor visitNotItemTest: self];
}


- (NSString *) description {
  NSString  *fmt =
    NSLocalizedStringFromTable( @"not (%@)" , @"Tests", 
                                @"NOT-test with 1: sub test" );

  return [NSString stringWithFormat: fmt, [subTest description]];
}


+ (NSObject *) objectFromDictionary: (NSDictionary *)dict {
  NSAssert([[dict objectForKey: @"class"] isEqualToString: @"NotItemTest"],
             @"Incorrect value for class in dictionary.");

  return [[[NotItemTest alloc] initWithPropertiesFromDictionary: dict]
           autorelease];
}

@end
