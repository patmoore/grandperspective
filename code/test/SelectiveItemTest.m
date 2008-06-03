#import "SelectiveItemTest.h"

#import "FileItemTestVisitor.h"
#import "FileItemTestRepository.h"


@implementation SelectiveItemTest

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithSubItemTest:onlyFiles: instead.");
}

- (id) initWithSubItemTest: (NSObject<FileItemTest> *)subTestVal 
         onlyFiles: (BOOL) onlyFilesVal {
  if (self = [super init]) {
    subTest = [subTestVal retain];
    
    onlyFiles = onlyFilesVal;
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
          
    onlyFiles = [[dict objectForKey: @"onlyFiles"] boolValue];
  }
  
  return self;
}

- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  [dict setObject: @"SelectiveItemTest" forKey: @"class"];

  [dict setObject: [subTest dictionaryForObject] forKey: @"subTest"];

  [dict setObject: [NSNumber numberWithBool: onlyFiles] forKey: @"onlyFiles"];
}


- (NSObject <FileItemTest> *) subItemTest {
  return subTest;
}

- (BOOL) applyToFilesOnly {
  return onlyFiles;
}


- (TestResult) testFileItem: (FileItem *)item context: (id)context {
  if ([item isDirectory] == onlyFiles) {
    // Test should not be applied to this type of item.
    return TEST_NOT_APPLICABLE;
  }
  
  return ( [subTest testFileItem: item context: context] 
           ? TEST_PASSED : TEST_FAILED );
}

- (void) acceptFileItemTestVisitor: (NSObject <FileItemTestVisitor> *)visitor {
  [visitor visitSelectiveItemTest: self];
}


- (NSString *) description {
  NSString  *format = ( onlyFiles 
                        ? NSLocalizedStringFromTable( 
                            @"(files: %@)", @"Tests",
                            @"Selective test with 1: sub test" )
                        : NSLocalizedStringFromTable( 
                            @"(folders: %@)", @"Tests",
                            @"Selective test with 1: sub test" ) );
  
  return [NSString stringWithFormat: format, [subTest description]];
}


+ (NSObject *) objectFromDictionary: (NSDictionary *)dict {  
  NSAssert([[dict objectForKey: @"class"] 
               isEqualToString: @"SelectiveItemTest"],
             @"Incorrect value for class in dictionary.");

  return [[[SelectiveItemTest alloc] initWithPropertiesFromDictionary: dict]
           autorelease];
}

@end

