#import "ScanTaskInput.h"

#import "PreferencesPanelControl.h"


@implementation ScanTaskInput

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithDirectoryName:fileSizeMeasure:filterTest instead");
}

- (id) initWithDirectoryName: (NSString *)dirNameVal 
         fileSizeMeasure: (NSString *)fileSizeMeasureVal
         filterTest: (NSObject <FileItemTest> *)filterTestVal {

  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  
  BOOL  showPackageContentsByDefault =
          ( [userDefaults boolForKey: ShowPackageContentsByDefaultKey]
            ? NSOnState : NSOffState );
            
  return [self initWithDirectoryName: dirNameVal
                 fileSizeMeasure: fileSizeMeasureVal
                 filterTest: filterTestVal
                 packagesAsFiles: !showPackageContentsByDefault];
}
         
- (id) initWithDirectoryName: (NSString *)dirNameVal 
         fileSizeMeasure: (NSString *)fileSizeMeasureVal
         filterTest: (NSObject <FileItemTest> *)filterTestVal
         packagesAsFiles: (BOOL) packagesAsFilesVal {
  if (self = [super init]) {
    dirName = [dirNameVal retain];
    fileSizeMeasure = [fileSizeMeasureVal retain];
    filterTest = [filterTestVal retain];
    packagesAsFiles = packagesAsFilesVal;
  }
  return self;
}

- (void) dealloc {
  [dirName release];
  [fileSizeMeasure release];
  [filterTest release];
  
  [super dealloc];
}


- (NSString *) directoryName {
  return dirName;
}

- (NSString *) fileSizeMeasure {
  return fileSizeMeasure;
}

- (NSObject <FileItemTest> *) filterTest {
  return filterTest;
}

- (BOOL) packagesAsFiles {
  return packagesAsFiles;
}

@end
