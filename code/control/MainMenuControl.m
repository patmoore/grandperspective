#import "MainMenuControl.h"

#import "DirectoryItem.h"

#import "DirectoryViewControl.h"
#import "DirectoryViewControlSettings.h"
#import "SaveImageDialogControl.h"
#import "EditFilterWindowControl.h"
#import "PreferencesPanelControl.h"

#import "ItemPathModel.h"
#import "TreeFilter.h"
#import "TreeContext.h"

#import "WindowManager.h"

#import "VisibleAsynchronousTaskManager.h"
#import "AsynchronousTaskManager.h"
#import "ScanTaskInput.h"
#import "ScanTaskExecutor.h"
#import "RescanTaskInput.h"
#import "RescanTaskExecutor.h"
#import "FilterTaskInput.h"
#import "FilterTaskExecutor.h"

#import "FileItemTestRepository.h"

NSString* scanActivityFormatString() {
  return NSLocalizedString( @"Scanning %@", 
                            @"Message in progress panel while scanning" );
}


@interface FreshDirViewWindowCreator : NSObject {
  WindowManager  *windowManager;
}

- (id) initWithWindowManager: (WindowManager *)windowManager;

- (void) createWindowForTree: (TreeContext *)treeContext;

- (DirectoryViewControl *) 
     createDirectoryViewControlForTree: (TreeContext *)treeContext;

@end // @interface FreshDirViewWindowCreator


@interface DerivedDirViewWindowCreator : FreshDirViewWindowCreator {
  ItemPathModel  *targetPath;
  DirectoryViewControlSettings  *settings;
}

- (id) initWithWindowManager:(WindowManager*)windowManager
         targetPath: (ItemPathModel *)targetPath
         settings: (DirectoryViewControlSettings *)settings;

@end // @interface DerivedDirViewWindowCreator


@interface MainMenuControl (PrivateMethods)

- (void) editFilterWindowCancelAction:(NSNotification*)notification;
- (void) editFilterWindowOkAction:(NSNotification*)notification;

- (void) duplicateCurrentWindowSharingPath: (BOOL) sharePathModel;

+ (NSString*) windowTitleForDirectoryView: (DirectoryViewControl *)control;

@end // @interface MainMenuControl (PrivateMethods)


@implementation MainMenuControl

+ (void) initialize {
  NSLog( @"Registering application defaults." );

  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  // Load application-defaults from the information properties file.
  NSBundle  *bundle = [NSBundle mainBundle];
      
  NSDictionary  *appDefaults = 
    [bundle objectForInfoDictionaryKey: @"GPApplicationDefaults"];

  [defaults registerDefaults: appDefaults];
}


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

- (void) applicationWillTerminate:(NSNotification *)notification {
  [[FileItemTestRepository defaultFileItemTestRepository]
       storeUserCreatedTests];
       
  [self release];
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
  [openPanel setCanChooseFiles: NO];
  [openPanel setCanChooseDirectories: YES];
  [openPanel setAllowsMultipleSelection: NO];
  
  [openPanel setTitle: 
     NSLocalizedString(@"Scan folder", @"Title of open panel") ];
  [openPanel setPrompt: 
     NSLocalizedString(@"Scan", @"Prompt in open panel") ];

  if ([openPanel runModalForTypes:nil] == NSOKButton) {
    NSString  *dirName = [[openPanel filenames] objectAtIndex:0];

    NSString  *fileSizeMeasure =
      [[NSUserDefaults standardUserDefaults] stringForKey: FileSizeMeasureKey];

    FreshDirViewWindowCreator  *windowCreator =
      [[FreshDirViewWindowCreator alloc] initWithWindowManager: windowManager];
    ScanTaskInput  *input = 
      [[ScanTaskInput alloc] initWithDirectoryName: dirName
                               fileSizeMeasure: fileSizeMeasure ];

    [rescanTaskManager abortTask];
    // The TreeBuilder implementation is such that only one scan can happen
    // at any one time. Therefore, we have to make sure that no rescan task
    // is currently being carried out. Note: any ongoing scan task will be
    // aborted implicitely by the scanTaskManager.
    
    NSString  *format = scanActivityFormatString();
    [scanTaskManager asynchronouslyRunTaskWithInput: input
                       description: 
                         [NSString stringWithFormat: format, dirName]
                       callback: windowCreator
                       selector: @selector(createWindowForTree:)];
                       
    [input release];
    [windowCreator release];
  }
}


- (IBAction) rescanDirectoryView:(id)sender {
  DirectoryViewControl  *oldControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];

  ItemPathModel  *itemPathModel = [oldControl itemPathModel];

  if (itemPathModel != nil) {
    NSString  *dirName = [[itemPathModel scanTree] stringForFileItemPath];
    
    DerivedDirViewWindowCreator  *windowCreator =
      [[DerivedDirViewWindowCreator alloc] 
          initWithWindowManager: windowManager
            targetPath: itemPathModel 
            settings: [oldControl directoryViewControlSettings]];

    RescanTaskInput  *input = 
      [[RescanTaskInput alloc] initWithOldContext: [oldControl treeContext]];
    
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
          name: CancelPerformedEvent object: editFilterWindowControl];
    [nc addObserver:self selector: @selector(editFilterWindowCancelAction:)
          name: ClosePerformedEvent object: editFilterWindowControl];
          // Closing a window can be considered the same as cancelling.
    [nc addObserver:self selector: @selector(editFilterWindowOkAction:)
          name: OkPerformedEvent object: editFilterWindowControl];

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
            settings: [oldControl directoryViewControlSettings]];
    
    FilterTaskInput  *input = 
      [[FilterTaskInput alloc] initWithOldContext: [oldControl treeContext]
                                 filterTest: filterTest];

    NSString  *format = NSLocalizedString( 
                          @"Filtering %@", 
                          @"Message in progress panel while filtering" );
    NSString  *pathName = [[oldPathModel scanTree] stringForFileItemPath];
    [filterTaskManager asynchronouslyRunTaskWithInput: input
                         description: 
                           [NSString stringWithFormat: format, pathName]
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
        initWithTreeContext: [oldControl treeContext]
          pathModel: itemPathModel
          settings: [oldControl directoryViewControlSettings]];
  // Note: The control should auto-release itself when its window closes
    
  // Force loading (and showing) of the window.
  [windowManager addWindow:[newControl window] 
                   usingTitle:[[oldControl window] title]];
}


// Creates window title based on scan location, scan time and filter (if any).
+ (NSString*) windowTitleForDirectoryView: (DirectoryViewControl *)control {
  TreeContext  *treeContext = [control treeContext];
  NSString  *scanPath = [[treeContext scanTree] stringForFileItemPath];

  NSString  *scanTimeString = 
    [[treeContext scanTime] descriptionWithCalendarFormat: @"%H:%M:%S"
                              timeZone: nil locale: nil];
  if ([treeContext filterIdentifier] == 0) {
    return [NSString stringWithFormat: @"%@ - %@", 
                                         scanPath, scanTimeString];
  }
  else {
    return [NSString stringWithFormat: @"%@ - %@ - %@", 
                                         scanPath, scanTimeString,
                                         [treeContext filterName] ];
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


- (void) createWindowForTree: (TreeContext *)treeContext {
  if (treeContext == nil) {
    // Reading failed or cancelled. Don't create a window.
    return;
  }

  // Note: The control should auto-release itself when its window closes  
  DirectoryViewControl  *dirViewControl = 
    [[self createDirectoryViewControlForTree: treeContext] retain];
  
  NSString  *title = 
    [MainMenuControl windowTitleForDirectoryView: dirViewControl];
  
  // Force loading (and showing) of the window.
  [windowManager addWindow: [dirViewControl window] usingTitle: title];
}

- (DirectoryViewControl*) 
     createDirectoryViewControlForTree: (TreeContext *)treeContext {
  return [[[DirectoryViewControl alloc] 
              initWithTreeContext: treeContext] autorelease];
}

@end // @implementation FreshDirViewWindowCreator


@implementation DerivedDirViewWindowCreator

// Overrides designated initialiser.
- (id) initWithWindowManager:(WindowManager*)windowManagerVal {
  NSAssert(NO, 
    @"Use initWithWindowManager:targetPath:settings instead.");
}

- (id) initWithWindowManager: (WindowManager *)windowManagerVal
         targetPath: (ItemPathModel *)targetPathVal
         settings: (DirectoryViewControlSettings *)settingsVal {
         
  if (self = [super initWithWindowManager: windowManagerVal]) {
    targetPath = [targetPathVal retain];
    // Note: The state of "targetPath" may change during scanning/filtering 
    // (which happens in the background). This is okay and even desired. When 
    // the callback occurs the path in the new window will match the current
    // path in the original window.
     
    settings = [settingsVal retain];
  }
  return self;
}

- (void) dealloc {
  [targetPath release];
  [settings release];
  
  [super dealloc];
}


- (DirectoryViewControl*) 
     createDirectoryViewControlForTree: (TreeContext *)treeContext {
       
  // Try to match the path.
  ItemPathModel  *path = 
    [[[ItemPathModel alloc] initWithTreeContext: treeContext] autorelease];

  [path suppressSelectedItemChangedNotifications: YES];

  NSEnumerator  *fileItemEnum = [[targetPath fileItemPath] objectEnumerator];
  FileItem  *targetItem;
  FileItem  *itemToSelect = nil;

  BOOL  insideScanTree = NO;
  BOOL  insideVisibleTree = NO;
  BOOL  hasVisibleItems = NO;
  
  while (targetItem = [fileItemEnum nextObject]) {
    if ( insideScanTree ) {
      // Only try to extend the visible path once we are inside the scan tree,
      // as "path" starts at its scan tree.
      if ( [path extendVisiblePathToSimilarFileItem: targetItem] ) {
        if (! insideVisibleTree) {
          [path moveVisibleTreeDown];
        }
        else {
          hasVisibleItems = YES;
        }
      }
      else {
        // Failure to match, so should stop matching remainder of path.
        break;
      }
    }
    if (itemToSelect == nil && targetItem == [targetPath selectedFileItem]) {
      itemToSelect = [path selectedFileItem];
    }
    if (!insideVisibleTree && targetItem == [targetPath visibleTree]) {
      // The remainder of this path can remain visible.
      insideVisibleTree = YES;
    }
    if (!insideScanTree && targetItem == [targetPath scanTree]) {
      // We can now start extending "path" to match "targetPath". 
      insideScanTree = YES;
    }
  }

  if (hasVisibleItems) {
    [path setVisiblePathLocking: YES];
  }
  
  if (itemToSelect != nil) {
    // Match the selection to that of the original path. This is needed, 
    // because the path endpoint is not necessarily the selected item.
    while ([path selectedFileItem] != itemToSelect) {
      [path moveSelectionUp];
    }
  }
  else {
    // Did not manage to match the new path all the way up to the selected
    // item in the original path. The selected item of the new path can 
    // therefore remain at its endpoint (as that is the closest it can come
    // to matching the old selection).
  }
        
  [path suppressSelectedItemChangedNotifications: NO];

  return [[[DirectoryViewControl alloc] 
             initWithTreeContext: treeContext pathModel: path 
               settings: settings] autorelease];
}

@end // @implementation DerivedDirViewWindowCreator
