#import "DrawTaskExecutor.h"

#import "ItemTreeDrawer.h"
#import "ItemTreeDrawerSettings.h"
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
                   [[[ItemTreeDrawerSettings alloc] init] autorelease]];
}

- (id) initWithTreeContext: (TreeContext *)treeContextVal
         drawingSettings: (ItemTreeDrawerSettings *)settings {
  if (self = [super init]) {
    treeContext = [treeContextVal retain];
  
    treeDrawer = 
      [[ItemTreeDrawer alloc] initWithScanTree: [treeContext scanTree]
                                treeDrawerSettings: settings];
    treeDrawerSettings = [settings retain];
    
    settingsLock = [[NSLock alloc] init];
    
    enabled = YES;
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
    
    [treeContext obtainReadLock];
    
    NSImage  *image = 
      [treeDrawer drawImageOfVisibleTree: [drawingInput visibleTree] 
                    startingAtTree: [drawingInput treeInView]
                    usingLayoutBuilder: [drawingInput layoutBuilder]
                    inRect: [drawingInput bounds]];
                         
    [treeContext releaseReadLock];
    
    return image;
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
