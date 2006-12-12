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
#import "CompoundAndItemTest.h"
#import "CompoundOrItemTest.h"
#import "NotItemTest.h"

#import "NotifyingDictionary.h"


@interface FileItemTestRepository (PrivateMethods) 

- (void) addTest:(NSObject <FileItemTest> *) test
           toDictionary:(NSMutableDictionary*) dict
           withName:(NSString*) name;

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
    
    NSBundle  *bundle = [NSBundle mainBundle];
    NSArray  *fileItemTestDicts = 
      [bundle objectForInfoDictionaryKey: @"GPDefaultFileItemTests"];

    NSDictionary  *fileItemTestDict;
    NSEnumerator  *fileItemTestDictEnum = [fileItemTestDicts objectEnumerator];

    while ((fileItemTestDict = [fileItemTestDictEnum nextObject]) != nil) {
      NSObject <FileItemTest>  *fileItemTest =
        [FileItemTestRepository fileItemTestFromDictionary: fileItemTestDict];

      [initialTestDictionary setObject: fileItemTest 
                               forKey: [fileItemTest name]];
    }
    
    testsByName = [[NotifyingDictionary alloc] 
                    initWithCapacity: 16 
                    initialContents: initialTestDictionary];
  }
  
  return self;
}

- (NotifyingDictionary*) testsByNameAsNotifyingDictionary {
  return testsByName;
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

- (void) addTest:(NSObject <FileItemTest> *) test
           toDictionary:(NSMutableDictionary*) dict
           withName:(NSString*) name {
  [test setName:name];
  [dict setObject:test forKey:name];
}

@end //  FileItemTestRepository (PrivateMethods) 
