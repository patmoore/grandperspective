#import "FilterTaskInput.h"

#import "TreeContext.h"
#import "PreferencesPanelControl.h"

@implementation FilterTaskInput

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithOldContext:filterTest: instead");
}

- (id) initWithOldContext: (TreeContext *)oldContextVal
         filterTest: (NSObject <FileItemTest> *)filterTestVal {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  
  BOOL  showPackageContentsByDefault =
          ( [userDefaults boolForKey: ShowPackageContentsByDefaultKey]
            ? NSOnState : NSOffState );

  return [self initWithOldContext: oldContextVal filterTest: filterTestVal
                 packagesAsFiles: !showPackageContentsByDefault];
}

- (id) initWithOldContext: (TreeContext *)oldContextVal
         filterTest: (NSObject <FileItemTest> *)filterTestVal
         packagesAsFiles: (BOOL) packagesAsFilesVal {
  if (self = [super init]) {
    oldContext = [oldContextVal retain];
    filterTest = [filterTestVal retain];
    
    packagesAsFiles = packagesAsFilesVal;
  }
  return self;
}

- (void) dealloc {
  [oldContext release];
  [filterTest release];
  
  [super dealloc];
}


- (TreeContext *) oldContext {
  return oldContext;
}

- (NSObject <FileItemTest> *) filterTest {
  return filterTest;
}

- (BOOL) packagesAsFiles {
  return packagesAsFiles;
}

@end
