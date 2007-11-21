#import "DrawTaskExecutor.h"

#import "ItemTreeDrawer.h"
#import "ItemTreeDrawerSettings.h"
#import "DrawTaskInput.h"


@implementation DrawTaskExecutor

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithVolumeTree: instead");
}

- (id) initWithVolumeTree: (DirectoryItem *)volumeTreeVal {
  return [self initWithVolumeTree: volumeTreeVal
                 treeDrawerSettings:
                   [[[ItemTreeDrawerSettings alloc] init] autorelease]];
}

- (id) initWithVolumeTree: (DirectoryItem *)volumeTree 
         treeDrawerSettings: (ItemTreeDrawerSettings *)settings {
  if (self = [super init]) {
    treeDrawer = [[ItemTreeDrawer alloc] initWithVolumeTree: volumeTree 
                                           treeDrawerSettings: settings];
    treeDrawerSettings = [settings retain];
    
    settingsLock = [[NSLock alloc] init];
    
    enabled = YES;
  }
  return self;
}

- (void) dealloc {
  [treeDrawer release];
  [treeDrawerSettings release];
  
  [settingsLock release];
  
  [super dealloc];
}


- (ItemTreeDrawerSettings *) treeDrawerSettings {
  return treeDrawerSettings;
}

- (void) setTreeDrawerSettings: (ItemTreeDrawerSettings *)settings {
  [settingsLock lock];
  if (settings != treeDrawerSettings) {
    [treeDrawerSettings release];
    treeDrawerSettings = [settings retain];
  }
  [settingsLock unlock];
}


- (id) runTaskWithInput: (id)input {
  if (enabled) {
    [settingsLock lock];
    // Even though the settings are immutable, obtaining the settingsLock
    // ensures that it is not de-allocated while it is being used. 
    [treeDrawer updateSettings: treeDrawerSettings];
    [settingsLock unlock];

    DrawTaskInput  *drawingInput = input;
    
    return [treeDrawer drawImageOfVisibleTree: [drawingInput visibleTree] 
                         usingLayoutBuilder: [drawingInput layoutBuilder]
                         inRect: [drawingInput bounds]];
  }
  else {
    return nil;
  }
}


- (void) disable {
  if (enabled) {
    enabled = NO;
    [treeDrawer abortDrawing];
  }
}

- (void) enable {
  enabled = YES;
}

@end
