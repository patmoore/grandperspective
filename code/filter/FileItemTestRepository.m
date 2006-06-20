#import "FileItemTestRepository.h"

#import "StringTest.h"
#import "StringSuffixTest.h"
#import "StringEqualityTest.h"
#import "FileItemTest.h"
#import "ItemNameTest.h"
#import "ItemTypeTest.h"
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

    NSObject <FileItemTest>  *fileTypeTest =
      [[[ItemTypeTest alloc] initWithTestForPlainFile:YES] autorelease];

    NSObject <FileItemTest>  *folderTypeTest =
      [[[ItemTypeTest alloc] initWithTestForPlainFile:NO] autorelease];
    [initialTestDictionary setObject:folderTypeTest forKey:@"Folders"];

    NSObject <FileItemTest>  *tinyFileSizeTest = // 0 - 1k
      [[[ItemSizeTest alloc] initWithUpperBound:1024] autorelease];
    NSArray  *tinyFileTests = 
      [NSArray arrayWithObjects:tinyFileSizeTest, fileTypeTest, nil];
    NSObject <FileItemTest>  *tinyFileTest = 
      [[[CompoundAndItemTest alloc] initWithSubItemTests:tinyFileTests] 
           autorelease];
    [initialTestDictionary setObject:tinyFileTest forKey:@"Tiny files"];
    
    NSObject <FileItemTest>  *smallFileSizeTest = // 1k - 10k
      [[[ItemSizeTest alloc] initWithLowerBound:1024
                                     upperBound:10240] autorelease];
    NSArray  *smallFileTests = 
      [NSArray arrayWithObjects:smallFileSizeTest, fileTypeTest, nil];
    NSObject <FileItemTest>  *smallFileTest = 
      [[[CompoundAndItemTest alloc] initWithSubItemTests:smallFileTests] 
           autorelease];
    [initialTestDictionary setObject:smallFileTest forKey:@"Small files"];

    NSObject <FileItemTest>  *mediumFileSizeTest = // 10k - 1M
      [[[ItemSizeTest alloc] initWithLowerBound:10240
                                     upperBound:1048576] autorelease];
    NSArray  *mediumFileTests = 
      [NSArray arrayWithObjects:mediumFileSizeTest, fileTypeTest, nil];
    NSObject <FileItemTest>  *mediumFileTest = 
      [[[CompoundAndItemTest alloc] initWithSubItemTests:mediumFileTests] 
           autorelease];
    [initialTestDictionary setObject:mediumFileTest forKey:@"Medium files"];

    NSObject <FileItemTest>  *largeFileSizeTest = // 1M - 100M
      [[[ItemSizeTest alloc] initWithLowerBound:1048576
                                     upperBound:104857600] autorelease];
    NSArray  *largeFileTests = 
      [NSArray arrayWithObjects:largeFileSizeTest, fileTypeTest, nil];
    NSObject <FileItemTest>  *largeFileTest = 
      [[[CompoundAndItemTest alloc] initWithSubItemTests:largeFileTests] 
           autorelease];
    [initialTestDictionary setObject:largeFileTest forKey:@"Large files"];

    NSObject <FileItemTest>  *hugeFileSizeTest = // 100M - ...
      [[[ItemSizeTest alloc] initWithLowerBound:104857600] autorelease];
    NSArray  *hugeFileTests = 
      [NSArray arrayWithObjects:hugeFileSizeTest, fileTypeTest, nil];
    NSObject <FileItemTest>  *hugeFileTest = 
      [[[CompoundAndItemTest alloc] initWithSubItemTests:hugeFileTests] 
           autorelease];
    [initialTestDictionary setObject:hugeFileTest forKey:@"Huge files"];

    NSArray  *imageExtensions = 
      [NSArray arrayWithObjects:@".jpg", @".JPG", @".png", @".PNG", @".gif", 
                                @".GIF", nil];
    NSObject <StringTest>  *imageStringTest = 
      [[[StringSuffixTest alloc] initWithMatchTargets:imageExtensions] 
           autorelease];
    NSObject <FileItemTest>  *imageNameTest =
      [[[ItemNameTest alloc] initWithStringTest:imageStringTest]
           autorelease];
    NSArray  *imageTests = 
      [NSArray arrayWithObjects:imageNameTest, fileTypeTest, nil];
    NSObject <FileItemTest>  *imageTest = 
      [[[CompoundAndItemTest alloc] initWithSubItemTests:imageTests] 
           autorelease];
    [initialTestDictionary setObject:imageTest forKey:@"Images"];
    
    NSArray  *musicExtensions = 
      [NSArray arrayWithObjects:@".mp3", @".MP3", @".wav", @".WAV", nil];
    NSObject <StringTest>  *musicStringTest = 
      [[[StringSuffixTest alloc] initWithMatchTargets:musicExtensions]
           autorelease];
    NSObject <FileItemTest>  *musicNameTest =
      [[[ItemNameTest alloc] initWithStringTest:musicStringTest]
           autorelease];
    NSArray  *musicTests = 
      [NSArray arrayWithObjects:musicNameTest, fileTypeTest, nil];
    NSObject <FileItemTest>  *musicTest = 
      [[[CompoundAndItemTest alloc] initWithSubItemTests:musicTests] 
           autorelease];
    [initialTestDictionary setObject:musicTest forKey:@"Music"];
    
    NSArray  *versionControlFolders = 
      [NSArray arrayWithObjects:@"CVS", @".svn", nil];
    NSObject <StringTest>  *versionControlStringTest = 
      [[[StringEqualityTest alloc] initWithMatchTargets:versionControlFolders] 
           autorelease];
    NSObject <FileItemTest>  *versionControlNameTest =
      [[[ItemNameTest alloc] initWithStringTest:versionControlStringTest]
           autorelease];
    NSArray  *versionControlTests = 
      [NSArray arrayWithObjects:versionControlNameTest, fileTypeTest, nil];
    NSObject <FileItemTest>  *versionControlTest = 
      [[[CompoundAndItemTest alloc] initWithSubItemTests:versionControlTests]
           autorelease];
    [initialTestDictionary setObject:versionControlTest 
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
