#import "FilterTestRepository.h"

#import "FileItemTest.h"
#import "SelectiveItemTest.h"

#import "ItemSizeTestFinder.h"

#import "NotifyingDictionary.h"


// The key for storing user tests
NSString  *UserTestsKey = @"filterTests";

// The old (pre 1.1.1) key for storing user tests (as an array)
NSString  *UserTestsKey_Array = @"fileItemTests";

// The key for storing application-provided tests
NSString  *AppTestsKey = @"GPDefaultFilterTests";


@interface FilterTestRepository (PrivateMethods) 

- (void) addStoredTestsFromDictionary:(NSDictionary *)testDicts
           toLiveTests:(NSMutableDictionary *)testsByName;

/* Handles reading of tests from old user preferences (pre 1.1.1)
 */
- (void) addStoredTestsFromArray:(NSArray *)testDicts
           toLiveTests:(NSMutableDictionary *)testsByName;

@end


@implementation FilterTestRepository

+ (FilterTestRepository *)defaultFilterTestRepository {
  static FilterTestRepository  *defaultFilterTestRepository = nil;

  if (defaultFilterTestRepository == nil) {
    defaultFilterTestRepository = [[FilterTestRepository alloc] init];
  }
  
  return defaultFilterTestRepository;
}


- (id) init {
  if (self = [super init]) {
    NSMutableDictionary*  initialTestDictionary = 
                            [NSMutableDictionary dictionaryWithCapacity: 16]; 
    
    // Load application-provided tests from the information properties file.
    NSBundle  *bundle = [NSBundle mainBundle];
      
    [self addStoredTestsFromDictionary: 
              [bundle objectForInfoDictionaryKey: AppTestsKey]
            toLiveTests: initialTestDictionary];
    applicationProvidedTests = 
      [[NSDictionary alloc] initWithDictionary: initialTestDictionary];

    // Load additional user-created tests from preferences.
    NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
    [self addStoredTestsFromDictionary: 
              [userDefaults dictionaryForKey: UserTestsKey]
            toLiveTests: initialTestDictionary];
    [self addStoredTestsFromArray: 
              [userDefaults arrayForKey: UserTestsKey_Array]
            toLiveTests: initialTestDictionary];

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


- (NotifyingDictionary *)testsByNameAsNotifyingDictionary {
  return testsByName;
}


- (FileItemTest *)fileItemTestForName:(NSString *)name {
  return [((NSDictionary *)testsByName) objectForKey: name];
}

- (FileItemTest *)applicationProvidedTestForName:(NSString *)name {
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
    FileItemTest  *fileItemTest = 
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

@end // @implementation FilterTestRepository


@implementation FilterTestRepository (PrivateMethods) 

- (void) addStoredTestsFromDictionary:(NSDictionary *)testDicts
           toLiveTests:(NSMutableDictionary *)testsByNameVal {
  NSString  *name;
  NSEnumerator  *nameEnum = [testDicts keyEnumerator];

  while (name = [nameEnum nextObject]) {
    NSDictionary  *filterTestDict = [testDicts objectForKey: name];
    FileItemTest  *fileItemTest =
      [FileItemTest fileItemTestFromDictionary: filterTestDict];
    
    [testsByNameVal setObject: fileItemTest forKey: name];
  }
}


- (void) addStoredTestsFromArray:(NSArray *)testDicts
           toLiveTests:(NSMutableDictionary *)testsByNameVal {
  NSDictionary  *fileItemTestDict;
  NSEnumerator  *fileItemTestDictEnum = [testDicts objectEnumerator];
  
  ItemSizeTestFinder  *sizeTestFinder = 
    [[[ItemSizeTestFinder alloc] init] autorelease];

  while ((fileItemTestDict = [fileItemTestDictEnum nextObject]) != nil) {
    FileItemTest  *fileItemTest =
      [FileItemTest fileItemTestFromDictionary: fileItemTestDict];
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
      
      FileItemTest  *subTest = fileItemTest;
      fileItemTest = [[[SelectiveItemTest alloc] initWithSubItemTest: subTest 
                                                   onlyFiles: YES] autorelease];
    }

    [testsByNameVal setObject: fileItemTest forKey: name];
  }
}

@end // @implementation FilterTestRepository (PrivateMethods) 
