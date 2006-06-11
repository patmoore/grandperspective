#import "FileItemTestRepository.h"

#import "StringTest.h"
#import "StringSuffixTest.h"
#import "StringEqualityTest.h"
#import "FileItemTest.h"
#import "ItemNameTest.h"
#import "ItemTypeTest.h"
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
    NSArray  *imageExtensions = 
      [NSArray arrayWithObjects:@".jpg", @".JPG", @".png", @".PNG", @".gif", 
                                @".GIF", nil];
    NSObject <StringTest>  *imageStringTest = 
      [[[StringSuffixTest alloc] initWithMatchTargets:imageExtensions] 
           autorelease];
    NSObject <FileItemTest>  *imageNameTest =
      [[[ItemNameTest alloc] initWithStringTest:imageStringTest]
           autorelease];
    NSObject <FileItemTest>  *imageTypeTest =
      [[[ItemTypeTest alloc] initWithTestForPlainFile:YES] autorelease];
    NSArray  *imageTests = 
      [NSArray arrayWithObjects:imageNameTest, imageTypeTest, nil];
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
    NSObject <FileItemTest>  *musicTypeTest =
      [[[ItemTypeTest alloc] initWithTestForPlainFile:YES] autorelease];
    NSArray  *musicTests = 
      [NSArray arrayWithObjects:musicNameTest, musicTypeTest, nil];
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
    NSObject <FileItemTest>  *versionControlTypeTest =
      [[[ItemTypeTest alloc] initWithTestForPlainFile:NO] autorelease];
    NSArray  *versionControlTests = 
      [NSArray arrayWithObjects:versionControlNameTest, versionControlTypeTest, 
                                nil];
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
