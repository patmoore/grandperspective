#import "FilterTaskInput.h"

#import "TreeContext.h"
#import "PreferencesPanelControl.h"


@implementation FilterTaskInput

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithOldContext:filterSet: instead");
}

- (id) initWithTreeContext:(TreeContext *)treeContextVal
         filterSet:(FilterSet *)filterSetVal {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  
  BOOL  showPackageContentsByDefault =
          ( [userDefaults boolForKey: ShowPackageContentsByDefaultKey]
            ? NSOnState : NSOffState );

  return [self initWithTreeContext: treeContextVal filterSet: filterSetVal
                 packagesAsFiles: !showPackageContentsByDefault];
}

- (id) initWithTreeContext:(TreeContext *)treeContextVal
         filterSet:(FilterSet *)filterSetVal
         packagesAsFiles:(BOOL) packagesAsFilesVal {
  if (self = [super init]) {
    treeContext = [treeContextVal retain];
    filterSet = [filterSetVal retain];
    
    packagesAsFiles = packagesAsFilesVal;
  }
  return self;
}

- (void) dealloc {
  [treeContext release];
  [filterSet release];
  
  [super dealloc];
}


- (TreeContext *) treeContext {
  return treeContext;
}

- (FilterSet *) filterSet {
  return filterSet;
}

- (BOOL) packagesAsFiles {
  return packagesAsFiles;
}

@end
