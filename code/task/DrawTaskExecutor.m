#import "DrawTaskExecutor.h"

#import "FileItem.h"
#import "ItemTreeDrawer.h"
#import "ItemTreeDrawerSettings.h"
#import "DrawTaskInput.h"


@implementation DrawTaskExecutor

// Overrides designated initialiser
- (id) init {
  return [self initWithTreeDrawerSettings:
                 [[[ItemTreeDrawerSettings alloc] init] autorelease]];
}

- (id) initWithTreeDrawerSettings: (ItemTreeDrawerSettings *)settings {
  if (self = [super init]) {
    treeDrawer = [[ItemTreeDrawer alloc] initWithTreeDrawerSettings: settings];
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
    
    return [treeDrawer drawImageOfItemTree: [drawingInput itemSubTree] 
                         usingLayoutBuilder: [drawingInput treeLayoutBuilder]
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
