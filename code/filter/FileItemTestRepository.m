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
                             [[NSMutableDictionary alloc] initWithCapacity:32];    
    
    // TODO: Should get this from user defaults eventually.    

    NSObject <FileItemTest>  *tinyFileSizeTest = // 0 - 1k
      [[[ItemSizeTest alloc] initWithUpperBound:1024] autorelease];
    [self addTest:tinyFileSizeTest toDictionary:initialTestDictionary 
            withName:@"Tiny files"];
    
    NSObject <FileItemTest>  *smallFileSizeTest = // 1k - 10k
      [[[ItemSizeTest alloc] initWithLowerBound:1024
                                     upperBound:10240] autorelease];
    [self addTest:smallFileSizeTest toDictionary:initialTestDictionary 
            withName:@"Small files"];

    NSObject <FileItemTest>  *mediumFileSizeTest = // 10k - 1M
      [[[ItemSizeTest alloc] initWithLowerBound:10240
                                     upperBound:1048576] autorelease];
    [self addTest:mediumFileSizeTest toDictionary:initialTestDictionary 
            withName:@"Medium files"];

    NSObject <FileItemTest>  *largeFileSizeTest = // 1M - 100M
      [[[ItemSizeTest alloc] initWithLowerBound:1048576
                                     upperBound:104857600] autorelease];
    [self addTest:largeFileSizeTest toDictionary:initialTestDictionary 
            withName:@"Large files"];

    NSObject <FileItemTest>  *hugeFileSizeTest = // 100M - ...
      [[[ItemSizeTest alloc] initWithLowerBound:104857600] autorelease];
    [self addTest:hugeFileSizeTest toDictionary:initialTestDictionary 
            withName:@"Huge files"];

    NSArray  *imageExtensions = 
      [NSArray arrayWithObjects:@".jpg", @".JPG", @".png", @".PNG", @".gif", 
                                @".GIF", nil];
    NSObject <StringTest>  *imageStringTest = 
      [[[StringSuffixTest alloc] initWithMatchTargets:imageExtensions] 
           autorelease];
    NSObject <FileItemTest>  *imageNameTest =
      [[[ItemNameTest alloc] initWithStringTest:imageStringTest]
           autorelease];
    [self addTest:imageNameTest toDictionary:initialTestDictionary 
            withName:@"Images"];
    
    NSArray  *musicExtensions = 
      [NSArray arrayWithObjects:@".mp3", @".MP3", @".wav", @".WAV", nil];
    NSObject <StringTest>  *musicStringTest = 
      [[[StringSuffixTest alloc] initWithMatchTargets:musicExtensions]
           autorelease];
    NSObject <FileItemTest>  *musicNameTest =
      [[[ItemNameTest alloc] initWithStringTest:musicStringTest]
           autorelease];
    [self addTest:musicNameTest toDictionary:initialTestDictionary 
            withName:@"Music"];
                
    NSArray  *versionControlFolders = 
      [NSArray arrayWithObjects:@"/CVS/", @"/.svn/", nil];
    NSObject <StringTest>  *versionControlStringTest = 
      [[[StringContainmentTest alloc] 
           initWithMatchTargets:versionControlFolders] autorelease];
    NSObject <FileItemTest>  *versionControlPathTest =
      [[[ItemPathTest alloc] initWithStringTest:versionControlStringTest]
           autorelease];
    [self addTest:versionControlPathTest toDictionary:initialTestDictionary 
            withName:@"Version control"];

    testsByName = [[NotifyingDictionary alloc] 
                    initWithCapacity:16 initialContents:initialTestDictionary];
  }
  
  return self;
}

- (NotifyingDictionary*) testsByNameAsNotifyingDictionary {
  return testsByName;
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
