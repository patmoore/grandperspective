#import "MainMenuControl.h"

#import "DirectoryItem.h"

#import "DirectoryViewControl.h"
#import "DirectoryViewControlSettings.h"
#import "SaveImageDialogControl.h"
#import "EditFilterWindowControl.h"
#import "PreferencesPanelControl.h"
#import "ItemPathModel.h"
#import "TreeFilter.h"
#import "TreeHistory.h"

#import "WindowManager.h"

#import "VisibleAsynchronousTaskManager.h"
#import "AsynchronousTaskManager.h"
#import "ScanTaskExecutor.h"
#import "RescanTaskInput.h"
#import "RescanTaskExecutor.h"
#import "FilterTaskInput.h"
#import "FilterTaskExecutor.h"


NSString* scanActivityFormatString() {
  return NSLocalizedString( @"Scanning %@", 
                            @"Message in progress panel while scanning" );
}


@interface FreshDirViewWindowCreator : NSObject {
  WindowManager  *windowManager;
}

- (id) initWithWindowManager:(WindowManager*)windowManager;

- (void) createWindowForTree:(DirectoryItem*)itemTree;

- (DirectoryViewControl*) 
     createDirectoryViewControlForTree:(DirectoryItem*)tree;

@end // @interface FreshDirViewWindowCreator


@interface DerivedDirViewWindowCreator : FreshDirViewWindowCreator {
  ItemPathModel  *targetPath;
  TreeHistory  *history;
  DirectoryViewControlSettings  *settings;
}

- (id) initWithWindowManager:(WindowManager*)windowManager
         targetPath: (ItemPathModel *)targetPath
         history: (TreeHistory *)history
         settings: (DirectoryViewControlSettings *)settings;

@end // @interface DerivedDirViewWindowCreator


@interface MainMenuControl (PrivateMethods)

- (void) editFilterWindowCancelAction:(NSNotification*)notification;
- (void) editFilterWindowOkAction:(NSNotification*)notification;

- (void) duplicateCurrentWindowSharingPath: (BOOL) sharePathModel;

+ (NSString*) windowTitleForDirectoryView: (DirectoryViewControl *)control;

@end // @interface MainMenuControl (PrivateMethods)


@implementation MainMenuControl

- (id) init {
  if (self = [super init]) {
    windowManager = [[WindowManager alloc] init];  

    AsynchronousTaskManager  *actualScanTaskManager = 
      [[[AsynchronousTaskManager alloc] initWithTaskExecutor:
          [[[ScanTaskExecutor alloc] init] autorelease]] autorelease];

    scanTaskManager =
      [[VisibleAsynchronousTaskManager alloc] 
         initWithTaskManager: actualScanTaskManager 
           panelTitle: NSLocalizedString ( @"Scanning in progress",
                                           @"Title of progress panel." )];
    
    AsynchronousTaskManager  *actualRescanTaskManager = 
      [[[AsynchronousTaskManager alloc] initWithTaskExecutor:
          [[[RescanTaskExecutor alloc] init] autorelease]] autorelease];

    rescanTaskManager =
      [[VisibleAsynchronousTaskManager alloc] 
         initWithTaskManager: actualRescanTaskManager 
           panelTitle: NSLocalizedString ( @"Rescanning in progress",
                                           @"Title of progress panel." ) ];
                   
    AsynchronousTaskManager  *actualFilterTaskManager = 
      [[[AsynchronousTaskManager alloc] initWithTaskExecutor:
          [[[FilterTaskExecutor alloc] init] autorelease]] autorelease];

    filterTaskManager =
      [[VisibleAsynchronousTaskManager alloc] 
         initWithTaskManager: actualFilterTaskManager 
           panelTitle: NSLocalizedString ( @"Filtering in progress",
                                           @"Title of progress panel." )];
  }
  return self;
}

- (void) dealloc {
  [windowManager release];
  
  [scanTaskManager dispose];
  [scanTaskManager release];
  [rescanTaskManager dispose];
  [rescanTaskManager release];
  [filterTaskManager dispose];
  [filterTaskManager release];
  
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
    
    FreshDirViewWindowCreator  *windowCreator =
      [[FreshDirViewWindowCreator alloc] initWithWindowManager: windowManager];

    [rescanTaskManager abortTask];
    // The TreeBuilder implementation is such that only one scan can happen
    // at any one time. Therefore, we have to make sure that no rescan task
    // is currently being carried out. Note: any ongoing scan task will be
    // aborted implicitely by the scanTaskManager.
    
    NSString  *format = scanActivityFormatString();
    [scanTaskManager asynchronouslyRunTaskWithInput: dirName 
                       description: 
                         [NSString stringWithFormat: format, dirName]
                       callback: windowCreator
                       selector: @selector(createWindowForTree:)];
                       
    [windowCreator release];
  }
}


- (IBAction) rescanDirectoryView:(id)sender {
  DirectoryViewControl  *oldControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];

  ItemPathModel  *itemPathModel = [oldControl itemPathModel];

  if (itemPathModel != nil) {
    NSString  *dirName = [itemPathModel rootFilePathName];
    TreeHistory  *oldHistory = [oldControl treeHistory];
    
    
    DerivedDirViewWindowCreator  *windowCreator =
      [[DerivedDirViewWindowCreator alloc] 
          initWithWindowManager: windowManager
            targetPath: itemPathModel 
            history: [oldHistory historyAfterRescanning]
            settings: [oldControl directoryViewControlSettings]];
    
    RescanTaskInput  *input = 
      [[RescanTaskInput alloc] initWithDirectoryName: dirName
                                 filterTest: [oldHistory fileItemFilter]];
    
    [scanTaskManager abortTask];
    // The TreeBuilder implementation is such that only one scan can happen
    // at any one time. Therefore, we have to make sure that no scan task
    // is currently being carried out. Note: any ongoing rescan task will be 
    // aborted implicitely by the rescanTaskManager.
    
    NSString  *format = scanActivityFormatString();
    [rescanTaskManager asynchronouslyRunTaskWithInput: input
                         description: 
                           [NSString stringWithFormat: format, dirName]
                         callback: windowCreator
                         selector: @selector(createWindowForTree:)];

    [input release];                       
    [windowCreator release];
  }
}


- (IBAction) filterDirectoryView:(id)sender {
  DirectoryViewControl  *oldControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];

  if (editFilterWindowControl == nil) {
    // Lazily create it
    editFilterWindowControl = [[EditFilterWindowControl alloc] init];
    
    NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector: @selector(editFilterWindowCancelAction:)
          name: @"cancelPerformed" object: editFilterWindowControl];
    [nc addObserver:self selector: @selector(editFilterWindowCancelAction:)
          name: @"closePerformed" object: editFilterWindowControl];
          // Closing a window can be considered the same as cancelling.
    [nc addObserver:self selector: @selector(editFilterWindowOkAction:)
          name: @"okPerformed" object: editFilterWindowControl];

    [[editFilterWindowControl window] setTitle: 
        NSLocalizedString( @"Apply filter", @"Window title" ) ];

    [editFilterWindowControl removeApplyButton];
  }  
  [editFilterWindowControl representFileItemTest: [oldControl fileItemMask]];
  
  int  status = [NSApp runModalForWindow: [editFilterWindowControl window]];
  [[editFilterWindowControl window] close];
    
  if (status == NSRunStoppedResponse) {
    // get rule from window
    NSObject <FileItemTest>  *filterTest =
      [editFilterWindowControl createFileItemTest];
      
    ItemPathModel  *oldPathModel = [oldControl itemPathModel];

    DerivedDirViewWindowCreator  *windowCreator =
      [[DerivedDirViewWindowCreator alloc] 
          initWithWindowManager: windowManager
            targetPath: oldPathModel
            history: [[oldControl treeHistory] 
                         historyAfterFiltering: filterTest]
            settings: [oldControl directoryViewControlSettings]];
    
    FilterTaskInput  *input = 
      [[FilterTaskInput alloc] initWithItemTree: [oldPathModel itemTree]
                                 filterTest: filterTest];

    NSString  *format = NSLocalizedString( 
                          @"Filtering %@", 
                          @"Message in progress panel while filtering" );
    [filterTaskManager asynchronouslyRunTaskWithInput: input
                         description: 
                           [NSString stringWithFormat: format,
                                       [oldPathModel rootFilePathName]]
                         callback: windowCreator
                         selector: @selector(createWindowForTree:)];

    [input release];
    [windowCreator release];
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

- (IBAction) editPreferences:(id)sender {
  // Panel auto-disposes when it is closed.
  PreferencesPanelControl  *preferencesPanelControl = 
    [[PreferencesPanelControl alloc] init];
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


// Creates window title based on scan location, scan time and filter (if any).
+ (NSString*) windowTitleForDirectoryView: (DirectoryViewControl *)control {
  TreeHistory  *history = [control treeHistory];
  NSString  *rootPathName = [[[control itemPathModel] itemTree] name];
                
  NSString  *scanTimeString = 
    [[history scanTime] descriptionWithCalendarFormat: @"%H:%M:%S"
                          timeZone: nil locale: nil];
  if ([history filterIdentifier] == 0) {
    return [NSString stringWithFormat: @"%@ - %@", 
                                         rootPathName, scanTimeString];
  }
  else {
    return [NSString stringWithFormat: @"%@ - %@ - %@", 
                                         rootPathName, scanTimeString,
                                         [history filterName] ];
  }
}


@end // @implementation MainMenuControl (PrivateMethods)


@implementation FreshDirViewWindowCreator

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

@end // @implementation FreshDirViewWindowCreator


@implementation DerivedDirViewWindowCreator

// Overrides designated initialiser.
- (id) initWithWindowManager:(WindowManager*)windowManagerVal {
  NSAssert(NO, 
    @"Use initWithWindowManager:targetPath:history:settings instead.");
}

- (id) initWithWindowManager: (WindowManager *)windowManagerVal
         targetPath: (ItemPathModel *)targetPathVal
         history: (TreeHistory *)historyVal
         settings: (DirectoryViewControlSettings *)settingsVal {
         
  if (self = [super initWithWindowManager:windowManagerVal]) {
    targetPath = [targetPathVal retain];
    // Note: The state of "targetPath" may change during scanning/filtering 
    // (which happens in the background). This is okay and even desired. When 
    // the callback occurs the path in the new window will match the current
    // path in the original window.
     
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

  return [[[DirectoryViewControl alloc] 
             initWithItemPathModel: path history: history settings: settings]
               autorelease];
}

@end // @implementation DerivedDirViewWindowCreator
