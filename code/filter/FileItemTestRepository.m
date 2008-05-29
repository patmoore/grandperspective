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

#import "NotifyingDictionary.h"


@interface FileItemTestRepository (PrivateMethods) 

- (void) addTestDictsFromArray: (NSArray *) testDicts
           toTestDictionary: (NSMutableDictionary*) testsByName;

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
                             [[NSMutableDictionary alloc] initWithCapacity: 16];    
    
    // Load application-provided tests from the information properties file.
    NSBundle  *bundle = [NSBundle mainBundle];
      
    [self addTestDictsFromArray: 
              [bundle objectForInfoDictionaryKey: @"GPDefaultFileItemTests"]
            toTestDictionary: initialTestDictionary];
    applicationProvidedTests = 
      [[NSDictionary alloc] initWithDictionary: initialTestDictionary];

    // Load additional user-created tests from preferences.
    NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
    [self addTestDictsFromArray: 
              [userDefaults arrayForKey: @"fileItemTests"]
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


- (NSObject <FileItemTest> *) applicationProvidedTestForName: (NSString *)name {
  return [applicationProvidedTests objectForKey: name];
}


- (void) storeUserCreatedTests {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  
  NSMutableArray  *testsArray = 
    [NSMutableArray arrayWithCapacity: [((NSDictionary*)testsByName) count]];

  NSString  *name;
  NSEnumerator  *testNameEnum = [((NSDictionary*)testsByName) keyEnumerator];

  while ((name = [testNameEnum nextObject]) != nil) {
    NSObject <FileItemTest>  *fileItemTest = 
      [((NSDictionary*)testsByName) objectForKey: name];

    if (fileItemTest != [applicationProvidedTests objectForKey: name]) {
      [testsArray addObject: [fileItemTest dictionaryForObject]];
    }
  }
    
  [userDefaults setObject: testsArray forKey: @"fileItemTests"];
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

- (void) addTestDictsFromArray: (NSArray *) testDicts
           toTestDictionary: (NSMutableDictionary*) testsByNameVal {
  NSDictionary  *fileItemTestDict;
  NSEnumerator  *fileItemTestDictEnum = [testDicts objectEnumerator];

  while ((fileItemTestDict = [fileItemTestDictEnum nextObject]) != nil) {
    NSObject <FileItemTest>  *fileItemTest =
      [FileItemTestRepository fileItemTestFromDictionary: fileItemTestDict];

    [testsByNameVal setObject: fileItemTest forKey: [fileItemTest name]];
  }
}

@end //  FileItemTestRepository (PrivateMethods) 
