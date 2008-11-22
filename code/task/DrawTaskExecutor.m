#import "DrawTaskExecutor.h"

#import "TreeDrawer.h"
#import "TreeDrawerSettings.h"
#import "DrawTaskInput.h"
#import "TreeContext.h"


@implementation DrawTaskExecutor

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithTreeContext: instead.");
}


- (id) initWithTreeContext: (TreeContext *)treeContextVal {
  return [self initWithTreeContext: treeContextVal 
                 drawingSettings:
                   [[[TreeDrawerSettings alloc] init] autorelease]];
}

- (id) initWithTreeContext: (TreeContext *)treeContextVal
         drawingSettings: (TreeDrawerSettings *)settings {
  if (self = [super init]) {
    treeContext = [treeContextVal retain];
  
    treeDrawer = 
      [[TreeDrawer alloc] initWithScanTree: [treeContext scanTree]
                            treeDrawerSettings: settings];
    treeDrawerSettings = [settings retain];
    
    settingsLock = [[NSLock alloc] init];
  }
  return self;
}

- (void) dealloc {
  [treeContext release];

  [treeDrawer release];
  [treeDrawerSettings release];
  
  [settingsLock release];
  
  [super dealloc];
}


- (TreeDrawerSettings *) treeDrawerSettings {
  return treeDrawerSettings;
}

- (void) setTreeDrawerSettings: (TreeDrawerSettings *)settings {
  [settingsLock lock];
  if (settings != treeDrawerSettings) {
    [treeDrawerSettings release];
    treeDrawerSettings = [settings retain];
  }
  [settingsLock unlock];
}


- (id) runTaskWithInput: (id)input {
  [settingsLock lock];
  // Even though the settings are immutable, obtaining the settingsLock
  // ensures that it is not de-allocated while it is being used. 
  [treeDrawer updateSettings: treeDrawerSettings];
  [settingsLock unlock];

  DrawTaskInput  *drawingInput = input;
    
  [treeContext obtainReadLock];
    
  NSImage  *image = 
    [treeDrawer drawImageOfVisibleTree: [drawingInput visibleTree] 
                  startingAtTree: [drawingInput treeInView]
                  usingLayoutBuilder: [drawingInput layoutBuilder]
                  inRect: [drawingInput bounds]];
                         
  [treeContext releaseReadLock];
    
  return image;
}


- (void) abortTask {
  [treeDrawer abortDrawing];
}

@end
