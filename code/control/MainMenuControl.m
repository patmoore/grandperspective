#import "MainMenuControl.h"

#import "DirectoryItem.h"

#import "DirectoryViewControl.h"
#import "DirectoryViewControlSettings.h"
#import "SaveImageDialogControl.h"
#import "EditFilterWindowControl.h"
#import "ItemPathModel.h"
#import "TreeFilter.h"
#import "TreeHistory.h"

#import "WindowManager.h"

#import "AsynchronousTaskManager.h"
#import "ScanTaskExecutor.h"


@interface PostScanWindowCreator : NSObject {
  WindowManager  *windowManager;
}

- (id) initWithWindowManager:(WindowManager*)windowManager;

- (void) createWindowForTree:(DirectoryItem*)itemTree;
- (DirectoryViewControl*) 
     createDirectoryViewControlForTree:(DirectoryItem*)tree;

@end


@interface PostRescanWindowCreator : PostScanWindowCreator {
  ItemPathModel  *targetPath;
  TreeHistory  *history;
  DirectoryViewControlSettings  *settings;
}

- (id) initWithWindowManager:(WindowManager*)windowManager
         targetPath: (ItemPathModel *)targetPath
         history: (TreeHistory *)history
         settings: (DirectoryViewControlSettings *)settings;

@end


@interface MainMenuControl (PrivateMethods)

- (void) editFilterWindowCancelAction:(NSNotification*)notification;
- (void) editFilterWindowOkAction:(NSNotification*)notification;

- (void) duplicateCurrentWindowSharingPath: (BOOL) sharePathModel;
- (void) duplicateCurrentWindowFiltered: (NSObject <FileItemTest> *)filterTest;

+ (NSString*) windowTitleForDirectoryView: (DirectoryViewControl *)control;

@end


@implementation MainMenuControl

- (id) init {
  if (self = [super init]) {
    windowManager = [[WindowManager alloc] init];  

    scanTaskManager = 
      [[AsynchronousTaskManager alloc] initWithTaskExecutor:
         [[[ScanTaskExecutor alloc] init] autorelease]];
  }
  return self;
}

- (void) dealloc {
  [windowManager release];
  
  [scanTaskManager dispose];
  [scanTaskManager release];
  
  [editFilterWindowControl release];

  [super dealloc];
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification {
  [self openDirectoryView:self];
}


- (BOOL) validateMenuItem:(NSMenuItem *)anItem {
  if ( [anItem action]==@selector(duplicateDirectoryView:) ||
       [anItem action]==@selector(twinDirectoryView:) ) {
    return ([[NSApplication sharedApplication] mainWindow] != nil);
  }
  
  if ( [anItem action]==@selector(saveDirectoryViewImage:) ||
       [anItem action]==@selector(rescanDirectoryView:) ||
       [anItem action]==@selector(filterDirectoryView:) ) {
    return ([[NSApplication sharedApplication] mainWindow] != nil);
  }
  
  return YES;
}


- (IBAction) openDirectoryView:(id)sender {
  NSOpenPanel  *openPanel = [NSOpenPanel openPanel];
  [openPanel setCanChooseFiles:NO];
  [openPanel setCanChooseDirectories:YES];
  [openPanel setAllowsMultipleSelection:NO];

  if ([openPanel runModalForTypes:nil] == NSOKButton) {
    NSString  *dirName = [[openPanel filenames] objectAtIndex:0];
    
    PostScanWindowCreator  *windowCreator =
      [[PostScanWindowCreator alloc] initWithWindowManager: windowManager];
      
    [scanTaskManager asynchronouslyRunTaskWithInput: dirName 
                       callBack: windowCreator
                       selector: @selector(createWindowForTree:)];
                       
    [windowCreator release];
  }
}


- (IBAction) rescanDirectoryView:(id)sender {
  NSLog(@"rescan");
  DirectoryViewControl  *oldControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];

  ItemPathModel  *itemPathModel = [oldControl itemPathModel];

  if (itemPathModel != nil) {
    NSString  *dirName = [itemPathModel rootFilePathName];
        
    PostRescanWindowCreator  *windowCreator =
      [[PostRescanWindowCreator alloc] 
          initWithWindowManager: windowManager
            targetPath: itemPathModel 
            history: [oldControl treeHistory]
            settings: [oldControl directoryViewControlSettings]];
    
    [scanTaskManager asynchronouslyRunTaskWithInput: dirName 
                       callBack: windowCreator
                       selector: @selector(createWindowForTree:)];
                       
    [windowCreator release];
  }
}


- (IBAction) filterDirectoryView:(id)sender {
  if (editFilterWindowControl == nil) {
    // Lazily create it
    editFilterWindowControl = [[EditFilterWindowControl alloc] init];
    
    NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(editFilterWindowCancelAction:)
          name:@"cancelPerformed" object:editFilterWindowControl];
    [nc addObserver:self selector:@selector(editFilterWindowOkAction:)
          name:@"okPerformed" object:editFilterWindowControl];

    [[editFilterWindowControl window] setTitle:@"Apply filter"];

    [editFilterWindowControl removeApplyButton];    
  }
  
  DirectoryViewControl  *viewControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];

  [editFilterWindowControl representFileItemTest:[viewControl fileItemMask]];
  
  int  status = [NSApp runModalForWindow:[editFilterWindowControl window]];
  [[editFilterWindowControl window] close];
    
  if (status == NSRunStoppedResponse) {
    // get rule from window
    NSObject <FileItemTest>  *fileItemTest =
      [editFilterWindowControl createFileItemTest];

    [self duplicateCurrentWindowFiltered: fileItemTest];
  }
  else {
    NSAssert(status == NSRunAbortedResponse, @"Unexpected status.");
  }
}


- (IBAction) duplicateDirectoryView:(id)sender {
  [self duplicateCurrentWindowSharingPath:NO];
}

- (IBAction) twinDirectoryView:(id)sender {
  [self duplicateCurrentWindowSharingPath:YES];
}


- (IBAction) saveDirectoryViewImage:(id)sender {
  DirectoryViewControl  *dirViewControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];

  // Dialog auto-disposes when its job is done.
  SaveImageDialogControl  *saveImageDialogControl = 
    [[SaveImageDialogControl alloc] 
        initWithDirectoryViewControl: dirViewControl];
}

@end // @implementation MainMenuControl


@implementation MainMenuControl (PrivateMethods)

- (void) editFilterWindowCancelAction:(NSNotification*)notification {
  [NSApp abortModal];
}

- (void) editFilterWindowOkAction:(NSNotification*)notification {
  [NSApp stopModal];
}


- (void) duplicateCurrentWindowSharingPath: (BOOL) sharePathModel {
  DirectoryViewControl  *oldControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];

  // Share or clone the path model.
  ItemPathModel  *itemPathModel = [oldControl itemPathModel];

  if (!sharePathModel) {
    itemPathModel = [[itemPathModel copy] autorelease];
  }

  DirectoryViewControl  *newControl = 
    [[DirectoryViewControl alloc] 
        initWithItemPathModel: itemPathModel
          history: [oldControl treeHistory]
          settings: [oldControl directoryViewControlSettings]];
  // Note: The control should auto-release itself when its window closes
    
  // Force loading (and showing) of the window.
  [windowManager addWindow:[newControl window] 
                   usingTitle:[[oldControl window] title]];
}


- (void) duplicateCurrentWindowFiltered: (NSObject <FileItemTest> *)filterTest {
           
  DirectoryViewControl  *oldControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];

  TreeFilter  *treeFilter = 
    [[[TreeFilter alloc] initWithFileItemTest:filterTest] autorelease];
  DirectoryItem  *itemTree = 
    [treeFilter filterItemTree:[[oldControl itemPathModel] itemTree]];

  ItemPathModel  *itemPathModel = 
                   [[[ItemPathModel alloc] initWithTree:itemTree] autorelease];

  TreeHistory  *treeHistory = 
    [[oldControl treeHistory] historyAfterFiltering:filterTest];

  DirectoryViewControl  *newControl = 
    [[DirectoryViewControl alloc] 
        initWithItemPathModel: itemPathModel
          history: treeHistory
          settings: [oldControl directoryViewControlSettings]];
  // Note: The control should auto-release itself when its window closes
    
  NSString  *title = [MainMenuControl windowTitleForDirectoryView: newControl];
    
  // Force loading (and showing) of the window.
  [windowManager addWindow: [newControl window] usingTitle: title];
}


// Creates window title based on scan location, scan time and filter (if any).
+ (NSString*) windowTitleForDirectoryView: (DirectoryViewControl *)control {
  TreeHistory  *history = [control treeHistory];
  NSString  *rootPathName = [[[control itemPathModel] itemTree] name];

  NSString  *title = 
    [NSString stringWithFormat:@"%@ - %@", rootPathName,
                [[history scanTime] descriptionWithCalendarFormat:@"%H:%M:%S"
                                      timeZone:nil locale:nil]];
  if ([history filterIdentifier] != 0) {
    title = [NSString stringWithFormat:@"%@ - Filter%d", title, 
                        [history filterIdentifier]];
  }

  return title;
}


@end // @implementation MainMenuControl (PrivateMethods)


@implementation PostScanWindowCreator

// Overrides designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithWindowManager: instead.");
}

- (id) initWithWindowManager:(WindowManager*)windowManagerVal {
  if (self = [super init]) {
    windowManager = [windowManagerVal retain];
  }
  return self;
}

- (void) dealloc {
  [windowManager release];
  
  [super dealloc];
}


- (void) createWindowForTree:(DirectoryItem*)itemTree {
  if (itemTree == nil) {
    // Reading failed or cancelled. Don't create a window.
    return;
  }

  // Note: The control should auto-release itself when its window closes  
  DirectoryViewControl  *dirViewControl = 
    [[self createDirectoryViewControlForTree:itemTree] retain];
  
  NSString  *title = 
    [MainMenuControl windowTitleForDirectoryView: dirViewControl];
  
  // Force loading (and showing) of the window.
  [windowManager addWindow: [dirViewControl window] usingTitle: title];
}

- (DirectoryViewControl*) 
     createDirectoryViewControlForTree:(DirectoryItem*)tree {
  return [[[DirectoryViewControl alloc] initWithItemTree:tree] autorelease];
}

@end // @implementation PostScanWindowCreator


@implementation PostRescanWindowCreator

// Overrides designated initialiser.
- (id) initWithWindowManager:(WindowManager*)windowManagerVal {
  NSAssert(NO, 
    @"Use initWithWindowManager:targetPath:filter:settings instead.");
}

- (id) initWithWindowManager: (WindowManager *)windowManagerVal
         targetPath: (ItemPathModel *)targetPathVal
         history: (TreeHistory *)historyVal
         settings: (DirectoryViewControlSettings *)settingsVal {
         
  if (self = [super initWithWindowManager:windowManagerVal]) {
    targetPath = [targetPathVal retain];
    // Note: The state of "targetPath" may change during scanning (which
    // happens in the background). This is okay though. When the scanning is 
    // done it will simply match the current state.
     
    history = [historyVal retain];
    settings = [settingsVal retain];
  }
  return self;
}

- (void) dealloc {
  [targetPath release];
  [history release];
  [settings release];
  
  [super dealloc];
}


- (DirectoryViewControl*) 
     createDirectoryViewControlForTree:(DirectoryItem*)tree {
  
  TreeHistory  *newHistory = [history historyAfterRescanning]; 
  
  // Apply the filter again.
  if ([history fileItemFilter] != nil) {
    TreeFilter  *treeFilter = 
      [[TreeFilter alloc] initWithFileItemTest: [history fileItemFilter]];
     
    tree = [treeFilter filterItemTree:tree];
    
    [treeFilter release];
  }
     
  // Try to match the path.
  ItemPathModel  *path = 
    [[[ItemPathModel alloc] initWithTree:tree] autorelease];

  [path suppressItemPathChangedNotifications:YES];
    
  BOOL  ok = YES;
  NSEnumerator  *fileItemEnum = nil;
  FileItem  *fileItem;
  
  fileItemEnum = [[targetPath invisibleFileItemPath] objectEnumerator];  
  [fileItemEnum nextObject]; // Skip the root.
  while (ok && (fileItem = [fileItemEnum nextObject])) {
    ok = [path extendVisibleItemPathToFileItemWithName:[fileItem name]];
  }
  // Make this extension "invisible".
  while ([path canMoveTreeViewDown]) {
    [path moveTreeViewDown];
  }
    
  if (ok && [targetPath visibleFileItemPath] != nil) {
    BOOL  hasVisibleItems = NO;
      
    fileItemEnum = [[targetPath visibleFileItemPath] objectEnumerator];
    while (ok && (fileItem = [fileItemEnum nextObject])) {
      ok = [path extendVisibleItemPathToFileItemWithName:[fileItem name]];
      if (ok) {
        hasVisibleItems = YES;
      }
    }
      
    if (hasVisibleItems) {
      [path setVisibleItemPathLocking:YES];
    }
  }
        
  [path suppressItemPathChangedNotifications:NO];

  return [[DirectoryViewControl alloc] 
            initWithItemPathModel: path 
            history: newHistory
            settings: settings];
}

@end // @implementation PostRescanWindowCreator
