#import "FilterTaskInput.h"

#import "TreeContext.h"
#import "PreferencesPanelControl.h"

@implementation FilterTaskInput

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithOldContext:filterTest: instead");
}

- (id) initWithTreeContext: (TreeContext *)treeContextVal
         filterTest: (NSObject <FileItemTest> *)filterTestVal {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  
  BOOL  showPackageContentsByDefault =
          ( [userDefaults boolForKey: ShowPackageContentsByDefaultKey]
            ? NSOnState : NSOffState );

  return [self initWithTreeContext: treeContextVal filterTest: filterTestVal
                 packagesAsFiles: !showPackageContentsByDefault];
}

- (id) initWithTreeContext: (TreeContext *)treeContextVal
         filterTest: (NSObject <FileItemTest> *)filterTestVal
         packagesAsFiles: (BOOL) packagesAsFilesVal {
  if (self = [super init]) {
    treeContext = [treeContextVal retain];
    filterTest = [filterTestVal retain];
    
    packagesAsFiles = packagesAsFilesVal;
  }
  return self;
}

- (void) dealloc {
  [treeContext release];
  [filterTest release];
  
  [super dealloc];
}


- (TreeContext *) treeContext {
  return treeContext;
}

- (NSObject <FileItemTest> *) filterTest {
  return filterTest;
}

- (BOOL) packagesAsFiles {
  return packagesAsFiles;
}

@end
