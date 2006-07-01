#import "FileItemTestRepository.h"

#import "StringTest.h"
#import "StringSuffixTest.h"
#import "StringEqualityTest.h"
#import "StringContainmentTest.h"
#import "FileItemTest.h"
#import "ItemNameTest.h"
#import "ItemPathTest.h"
#import "ItemSizeTest.h"
#import "CompoundAndItemTest.h"

#import "../util/NotifyingDictionary.h"


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
                             [[NSMutableDictionary alloc] initWithCapacity:32];    
    
    // TODO: Should get this from user defaults eventually.    

    NSObject <FileItemTest>  *tinyFileSizeTest = // 0 - 1k
      [[[ItemSizeTest alloc] initWithUpperBound:1024] autorelease];
    [initialTestDictionary setObject:tinyFileSizeTest forKey:@"Tiny files"];
    
    NSObject <FileItemTest>  *smallFileSizeTest = // 1k - 10k
      [[[ItemSizeTest alloc] initWithLowerBound:1024
                                     upperBound:10240] autorelease];
    [initialTestDictionary setObject:smallFileSizeTest forKey:@"Small files"];

    NSObject <FileItemTest>  *mediumFileSizeTest = // 10k - 1M
      [[[ItemSizeTest alloc] initWithLowerBound:10240
                                     upperBound:1048576] autorelease];
    [initialTestDictionary setObject:mediumFileSizeTest forKey:@"Medium files"];

    NSObject <FileItemTest>  *largeFileSizeTest = // 1M - 100M
      [[[ItemSizeTest alloc] initWithLowerBound:1048576
                                     upperBound:104857600] autorelease];
    [initialTestDictionary setObject:largeFileSizeTest forKey:@"Large files"];

    NSObject <FileItemTest>  *hugeFileSizeTest = // 100M - ...
      [[[ItemSizeTest alloc] initWithLowerBound:104857600] autorelease];
    [initialTestDictionary setObject:hugeFileSizeTest forKey:@"Huge files"];

    NSArray  *imageExtensions = 
      [NSArray arrayWithObjects:@".jpg", @".JPG", @".png", @".PNG", @".gif", 
                                @".GIF", nil];
    NSObject <StringTest>  *imageStringTest = 
      [[[StringSuffixTest alloc] initWithMatchTargets:imageExtensions] 
           autorelease];
    NSObject <FileItemTest>  *imageNameTest =
      [[[ItemNameTest alloc] initWithStringTest:imageStringTest]
           autorelease];
    [initialTestDictionary setObject:imageNameTest forKey:@"Images"];
    
    NSArray  *musicExtensions = 
      [NSArray arrayWithObjects:@".mp3", @".MP3", @".wav", @".WAV", nil];
    NSObject <StringTest>  *musicStringTest = 
      [[[StringSuffixTest alloc] initWithMatchTargets:musicExtensions]
           autorelease];
    NSObject <FileItemTest>  *musicNameTest =
      [[[ItemNameTest alloc] initWithStringTest:musicStringTest]
           autorelease];
    [initialTestDictionary setObject:musicNameTest forKey:@"Music"];
    
    NSArray  *versionControlFolders = 
      [NSArray arrayWithObjects:@"/CVS/", @"/.svn/", nil];
    NSObject <StringTest>  *versionControlStringTest = 
      [[[StringContainmentTest alloc] 
           initWithMatchTargets:versionControlFolders] autorelease];
    NSObject <FileItemTest>  *versionControlPathTest =
      [[[ItemPathTest alloc] initWithStringTest:versionControlStringTest]
           autorelease];
    [initialTestDictionary setObject:versionControlPathTest 
                             forKey:@"Version control"];

    testsByName = [[NotifyingDictionary alloc] 
                    initWithCapacity:16 initialContents:initialTestDictionary];
  }
  
  return self;
}

- (NotifyingDictionary*) testsByNameAsNotifyingDictionary {
  return testsByName;
}

@end
