#import "FileItemTestRepository.h"

#import "StringTest.h"
#import "StringPrefixTest.h"
#import "StringSuffixTest.h"
#import "StringEqualityTest.h"
#import "StringContainmentTest.h"

#import "FileItemTest.h"
#import "ItemNameTest.h"
#import "ItemPathTest.h"
#import "ItemSizeTest.h"
#import "ItemTypeTest.h"
#import "ItemFlagsTest.h"
#import "SelectiveItemTest.h"
#import "CompoundAndItemTest.h"
#import "CompoundOrItemTest.h"
#import "NotItemTest.h"

#import "ItemSizeTestFinder.h"

#import "NotifyingDictionary.h"


// The key for storing user tests
NSString  *UserTestsKey = @"filterTests";

// The old (pre 1.1.1) key for storing user tests (as an array)
NSString  *UserTestsKey_Array = @"fileItemTests";

// The key for storing application-provided tests
NSString  *AppTestsKey = @"GPDefaultFilterTests";


@interface FileItemTestRepository (PrivateMethods) 

- (void) addTestDictsFromDictionary: (NSDictionary *)testDicts
           toTestDictionary: (NSMutableDictionary *)testsByName;

/* Handles reading of tests from old user preferences (pre 1.1.1)
 */
- (void) addTestDictsFromArray: (NSArray *)testDicts
           toTestDictionary: (NSMutableDictionary *)testsByName;

@end


@implementation FileItemTestRepository

static FileItemTestRepository  *defaultFileItemTestRepository = nil;

+ (FileItemTestRepository*) defaultFileItemTestRepository {
  if (defaultFileItemTestRepository == nil) {
    defaultFileItemTestRepository = [[FileItemTestRepository alloc] init];
  }
  
  return defaultFileItemTestRepository;
}


- (id) init {
  if (self = [super init]) {
    NSMutableDictionary*  initialTestDictionary = 
                            [NSMutableDictionary dictionaryWithCapacity: 16]; 
    
    // Load application-provided tests from the information properties file.
    NSBundle  *bundle = [NSBundle mainBundle];
      
    [self addTestDictsFromDictionary: 
              [bundle objectForInfoDictionaryKey: AppTestsKey]
            toTestDictionary: initialTestDictionary];
    applicationProvidedTests = 
      [[NSDictionary alloc] initWithDictionary: initialTestDictionary];

    // Load additional user-created tests from preferences.
    NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
    [self addTestDictsFromDictionary: 
              [userDefaults dictionaryForKey: UserTestsKey]
            toTestDictionary: initialTestDictionary];
    [self addTestDictsFromArray: 
              [userDefaults arrayForKey: UserTestsKey_Array]
            toTestDictionary: initialTestDictionary];

    // Store tests in a NotifyingDictionary
    testsByName = [[NotifyingDictionary alloc] 
                      initWithCapacity: 16 
                      initialContents: initialTestDictionary];
  }
  
  return self;
}

- (void) dealloc {
  [testsByName release];
  [applicationProvidedTests release];

  [super dealloc];
}


- (NotifyingDictionary*) testsByNameAsNotifyingDictionary {
  return testsByName;
}


- (NSObject <FileItemTest> *) fileItemTestForName:(NSString *)name {
  return [((NSDictionary *)testsByName) objectForKey: name];
}

- (NSObject <FileItemTest> *) applicationProvidedTestForName: (NSString *)name {
  return [applicationProvidedTests objectForKey: name];
}


- (void) storeUserCreatedTests {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  
  NSMutableDictionary  *testsDict = 
    [NSMutableDictionary dictionaryWithCapacity: 
                           [((NSDictionary *)testsByName) count]];

  NSString  *name;
  NSEnumerator  *nameEnum = [((NSDictionary *)testsByName) keyEnumerator];

  while ((name = [nameEnum nextObject]) != nil) {
    NSObject <FileItemTest>  *fileItemTest = 
      [((NSDictionary *)testsByName) objectForKey: name];

    if (fileItemTest != [applicationProvidedTests objectForKey: name]) {
      [testsDict setObject: [fileItemTest dictionaryForObject] forKey: name];
    }
  }
    
  [userDefaults setObject: testsDict forKey: UserTestsKey];
  // Ensure that the old key, which has been superseded, is removed.
  [userDefaults removeObjectForKey: UserTestsKey_Array];

  [userDefaults synchronize];
}


+ (NSObject <FileItemTest> *) fileItemTestFromDictionary: (NSDictionary *)dict {
  NSString  *classString = [dict objectForKey: @"class"];
  
  if ([classString isEqualToString: @"ItemSizeTest"]) {
    return [ItemSizeTest objectFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"CompoundAndItemTest"]) {
    return [CompoundAndItemTest objectFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"CompoundOrItemTest"]) {
    return [CompoundOrItemTest objectFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"NotItemTest"]) {
    return [NotItemTest objectFromDictionary: dict];
  } 
  else if ([classString isEqualToString: @"ItemNameTest"]) {
    return [ItemNameTest objectFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"ItemPathTest"]) {
    return [ItemPathTest objectFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"ItemTypeTest"]) {
    return [ItemTypeTest objectFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"ItemFlagsTest"]) {
    return [ItemFlagsTest objectFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"SelectiveItemTest"]) {
    return [SelectiveItemTest objectFromDictionary: dict];
  }

  
  NSAssert1(NO, @"Unrecognized file item test class \"%@\".", classString);
}

+ (NSObject <StringTest> *) stringTestFromDictionary: (NSDictionary *)dict {
  NSString  *classString = [dict objectForKey: @"class"];
  
  if ([classString isEqualToString: @"StringContainmentTest"]) {
    return [StringContainmentTest objectFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"StringSuffixTest"]) {
    return [StringSuffixTest objectFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"StringPrefixTest"]) {
    return [StringPrefixTest objectFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"StringEqualityTest"]) {
    return [StringEqualityTest objectFromDictionary: dict];
  }

  NSAssert1(NO, @"Unrecognized string test class \"%@\".", classString);
}

@end // FileItemTestRepository


@implementation FileItemTestRepository (PrivateMethods) 

- (void) addTestDictsFromDictionary: (NSDictionary *)testDicts
           toTestDictionary: (NSMutableDictionary *)testsByNameVal {
  NSString  *name;
  NSEnumerator  *nameEnum = [testDicts keyEnumerator];

  while (name = [nameEnum nextObject]) {
    NSDictionary  *filterTestDict = [testDicts objectForKey: name];
    NSObject <FileItemTest>  *fileItemTest =
      [FileItemTestRepository fileItemTestFromDictionary: filterTestDict];
    
    [testsByNameVal setObject: fileItemTest forKey: name];
  }
}


- (void) addTestDictsFromArray: (NSArray *)testDicts
           toTestDictionary: (NSMutableDictionary *)testsByNameVal {
  NSDictionary  *fileItemTestDict;
  NSEnumerator  *fileItemTestDictEnum = [testDicts objectEnumerator];
  
  ItemSizeTestFinder  *sizeTestFinder = 
    [[[ItemSizeTestFinder alloc] init] autorelease];

  while ((fileItemTestDict = [fileItemTestDictEnum nextObject]) != nil) {
    NSObject <FileItemTest>  *fileItemTest =
      [FileItemTestRepository fileItemTestFromDictionary: fileItemTestDict];
    NSString  *name = [fileItemTestDict objectForKey: @"name"];
    
    // Update tests stored by older versions of GrandPerspective (pre 0.9.12).
    [sizeTestFinder reset];
    [fileItemTest acceptFileItemTestVisitor: sizeTestFinder];
    if ( [sizeTestFinder itemSizeTestFound] 
         && ! [fileItemTest isKindOfClass: [SelectiveItemTest class]] ) {
      // The test includes an ItemSizeTest, which should only be applied to
      // files, yet it does not use a SelectiveItemTest, so add one. This can 
      // happen because before Version 0.9.12 test were only applied to files, 
      // so a SelectiveItemTest was not yet used, whereas it is needed now 
      // that test can also be applied to folders. Note, there is no need to
      // check for other file-only tests, as these did not yet exist before
      // Version 0.9.12.
      
      NSLog( @"Wrapping SelectiveItemTest around \"%@\" test.", name);
      
      NSObject <FileItemTest>  *subTest = fileItemTest;
      fileItemTest = [[[SelectiveItemTest alloc] initWithSubItemTest: subTest 
                                                   onlyFiles: YES] autorelease];
    }

    [testsByNameVal setObject: fileItemTest forKey: name];
  }
}

@end //  FileItemTestRepository (PrivateMethods) 
