#import "MainMenuControl.h"

#import "DirectoryItem.h"

#import "ControlConstants.h"

#import "DirectoryViewControl.h"
#import "DirectoryViewControlSettings.h"
#import "SaveImageDialogControl.h"
#import "EditFilterWindowControl.h"
#import "PreferencesPanelControl.h"

#import "ItemPathModel.h"
#import "ItemPathModelView.h"
#import "TreeFilter.h"
#import "TreeWriter.h"
#import "TreeReader.h"
#import "TreeContext.h"

#import "WindowManager.h"

#import "VisibleAsynchronousTaskManager.h"
#import "ScanProgressPanelControl.h"
#import "FilterProgressPanelControl.h"
#import "ScanTaskInput.h"
#import "ScanTaskExecutor.h"
#import "FilterTaskInput.h"
#import "FilterTaskExecutor.h"

#import "FileItemTest.h"
#import "FileItemTestRepository.h"

#import "UniformTypeRanking.h"
#import "UniformTypeInventory.h"


static int  nextFilterId = 1;


@interface ModalityTerminator : NSObject {
}

- (void) abortModalAction: (NSNotification *)notification;
- (void) stopModalAction: (NSNotification *)notification;

@end


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

- (void) scanFolderUsingFilter: (BOOL) useFilter;
- (void) duplicateCurrentWindowSharingPath: (BOOL) sharePathModel;

- (NSObject <FileItemTest> *) getFilter: (NSObject <FileItemTest> *)initialTest;

+ (NSString*) windowTitleForDirectoryView: (DirectoryViewControl *)control;

@end // @interface MainMenuControl (PrivateMethods)


@implementation MainMenuControl

+ (void) initialize {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  // Load application-defaults from the information properties file.
  NSBundle  *bundle = [NSBundle mainBundle];
      
  NSDictionary  *appDefaults = 
    [bundle objectForInfoDictionaryKey: @"GPApplicationDefaults"];

  [defaults registerDefaults: appDefaults];
  
  // Load the ranked list of uniform types and observe the inventory to ensure 
  // that it will be extended when new types are encountered (as a result of
  // scanning).
  UniformTypeRanking  *uniformTypeRanking = 
    [UniformTypeRanking defaultUniformTypeRanking];
  UniformTypeInventory  *uniformTypeInventory = 
    [UniformTypeInventory defaultUniformTypeInventory];
    
  [uniformTypeRanking loadRanking: uniformTypeInventory];

  // Observe the inventory for newly added types. Note: we do not want to
  // receive notifications about types that have been added to the
  // inventory as a result of the recent invocation of -loadRanking:. Calling 
  // -observerUniformTypeInventory: using -performSelectorOnMainThread:...
  // ensures that any pending notifications are fired before uniformTypeRanking
  // is added as an observer. 
  [uniformTypeRanking 
     performSelectorOnMainThread: @selector(observeUniformTypeInventory:)
     withObject: uniformTypeInventory waitUntilDone: NO];
}


- (id) init {
  if (self = [super init]) {
    windowManager = [[WindowManager alloc] init];  

    ProgressPanelControl  *scanProgressPanelControl = 
      [[[ScanProgressPanelControl alloc] 
           initWithTaskExecutor: [[[ScanTaskExecutor alloc] init] autorelease] 
       ] autorelease];

    scanTaskManager =
      [[VisibleAsynchronousTaskManager alloc] 
          initWithProgressPanel: scanProgressPanelControl];    

    ProgressPanelControl  *filterProgressPanelControl = 
      [[[FilterProgressPanelControl alloc] 
           initWithTaskExecutor: [[[FilterTaskExecutor alloc] init] autorelease]
       ] autorelease];

    filterTaskManager =
      [[VisibleAsynchronousTaskManager alloc] 
          initWithProgressPanel: filterProgressPanelControl];
  }
  return self;
}

- (void) dealloc {
  [windowManager release];
  
  [scanTaskManager dispose];
  [scanTaskManager release];

  [filterTaskManager dispose];
  [filterTaskManager release];
  
  [preferencesPanelControl release];
  
  [super dealloc];
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification {
  [self scanDirectoryView: self];
}

- (void) applicationWillTerminate:(NSNotification *)notification {
  [[FileItemTestRepository defaultFileItemTestRepository]
       storeUserCreatedTests];
       
  [[UniformTypeRanking defaultUniformTypeRanking] storeRanking];
       
  [self release];
}

- (BOOL) validateMenuItem:(NSMenuItem *)anItem {
  if ( [anItem action]==@selector(duplicateDirectoryView:) ||
       [anItem action]==@selector(twinDirectoryView:) ) {
    return ([[NSApplication sharedApplication] mainWindow] != nil);
  }
  
  if ( [anItem action]==@selector(saveScanData:) ||
       [anItem action]==@selector(saveDirectoryViewImage:) ||
       [anItem action]==@selector(rescanDirectoryView:) ||
       [anItem action]==@selector(filterDirectoryView:) ) {
    return ([[NSApplication sharedApplication] mainWindow] != nil);
  }
  
  return YES;
}


- (IBAction) scanDirectoryView: (id) sender {
  [self scanFolderUsingFilter: NO];
}

- (IBAction) scanFilteredDirectoryView: (id) sender {
  [self scanFolderUsingFilter: YES];
}


- (IBAction) rescanDirectoryView:(id)sender {
  DirectoryViewControl  *oldControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];

  ItemPathModel  *pathModel = [[oldControl pathModelView] pathModel];

  if (pathModel == nil) {
    return;
  }
  
  DerivedDirViewWindowCreator  *windowCreator =
    [[DerivedDirViewWindowCreator alloc] 
        initWithWindowManager: windowManager
          targetPath: pathModel
          settings: [oldControl directoryViewControlSettings]];

  TreeContext  *oldContext = [oldControl treeContext];
  ScanTaskInput  *input = 
    [[ScanTaskInput alloc] 
        initWithPath: [[oldContext scanTree] path]
          fileSizeMeasure: [oldContext fileSizeMeasure]
          filterTest: [oldContext fileItemFilter]];
    
  [scanTaskManager asynchronouslyRunTaskWithInput: input
                     callback: windowCreator
                     selector: @selector(createWindowForTree:)];

  [input release];                       
  [windowCreator release];
}


- (IBAction) filterDirectoryView:(id)sender {
  DirectoryViewControl  *oldControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];

  NSObject <FileItemTest>  *filterTest =
    [self getFilter: [oldControl fileItemMask]];
    
  if (filterTest == nil) {
    return;
  }
      
  ItemPathModel  *oldPathModel = [[oldControl pathModelView] pathModel];
  DirectoryViewControlSettings  *oldSettings = 
    [oldControl directoryViewControlSettings];

  DerivedDirViewWindowCreator  *windowCreator =
    [[DerivedDirViewWindowCreator alloc] 
        initWithWindowManager: windowManager
          targetPath: oldPathModel
          settings: oldSettings];

  FilterTaskInput  *input = 
    [[FilterTaskInput alloc] 
        initWithOldContext: [oldControl treeContext]
          filterTest: filterTest
          packagesAsFiles: ! [oldSettings showPackageContents]];

  [filterTaskManager asynchronouslyRunTaskWithInput: input
                       callback: windowCreator
                       selector: @selector(createWindowForTree:)];

  [input release];
  [windowCreator release];
}


- (IBAction) duplicateDirectoryView:(id)sender {
  [self duplicateCurrentWindowSharingPath:NO];
}

- (IBAction) twinDirectoryView:(id)sender {
  [self duplicateCurrentWindowSharingPath:YES];
}


- (IBAction) saveScanData: (id) sender {
  DirectoryViewControl  *dirViewControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];
    
  NSSavePanel  *savePanel = [NSSavePanel savePanel];  
  [savePanel setRequiredFileType: @"xml"];
  [savePanel setTitle: 
     NSLocalizedString( @"Save scan data", @"Title of save panel") ];
  
  if ([savePanel runModal] == NSOKButton) {
    NSString  *filename = [savePanel filename];
    
    TreeWriter  *treeWriter = [[[TreeWriter alloc] init] autorelease];

    if (! [treeWriter writeTree: [dirViewControl treeContext] 
                        toFile: filename]) {
      NSAlert *alert = [[[NSAlert alloc] init] autorelease];

      [alert addButtonWithTitle: OK_BUTTON_TITLE];
      [alert setMessageText: 
        NSLocalizedString( @"Failed to save the scan data.", 
                           @"Alert message" )];

      [alert runModal];
    }
  }
}


- (IBAction) loadScanData: (id) sender {
  DirectoryViewControl  *dirViewControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];
    
  NSOpenPanel  *openPanel = [NSOpenPanel openPanel];  
  [openPanel setRequiredFileType: @"xml"];
  [openPanel setTitle: 
     NSLocalizedString( @"Load scan data", @"Title of load panel") ];
  
  if ([openPanel runModal] == NSOKButton) {
    NSString  *filename = [openPanel filename];
    
    TreeReader  *treeReader = [[[TreeReader alloc] init] autorelease];

    TreeContext  *treeContext = [treeReader readTreeFromFile: filename];
      
    if (treeContext != nil) {
      FreshDirViewWindowCreator  *windowCreator =
        [[[FreshDirViewWindowCreator alloc] 
             initWithWindowManager: windowManager] autorelease];
      
      [windowCreator createWindowForTree: treeContext];
    }
    else if (! [treeReader aborted]) {
      NSAlert *alert = [[[NSAlert alloc] init] autorelease];

      [alert addButtonWithTitle: OK_BUTTON_TITLE];
      [alert setMessageText: 
        NSLocalizedString( @"Failed to load the scan data.", 
                           @"Alert message" )];
      if ([treeReader error] != nil) {
        [alert setInformativeText: [[treeReader error] localizedDescription]];
      }

      [alert runModal];
    }
  }
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
  if (preferencesPanelControl == nil) {
    // Lazily create the panel
    preferencesPanelControl = [[PreferencesPanelControl alloc] init];
  }

  [[preferencesPanelControl window] makeKeyAndOrderFront: self];
}

@end // @implementation MainMenuControl


@implementation MainMenuControl (PrivateMethods)

- (void) scanFolderUsingFilter: (BOOL) useFilter {
  NSOpenPanel  *openPanel = [NSOpenPanel openPanel];
  [openPanel setCanChooseFiles: NO];
  [openPanel setCanChooseDirectories: YES];
  [openPanel setAllowsMultipleSelection: NO];
  
  [openPanel setTitle: NSLocalizedString(@"Scan folder", 
                                         @"Title of open panel") ];
  [openPanel setPrompt: NSLocalizedString(@"Scan", @"Prompt in open panel") ];

  if ([openPanel runModalForTypes:nil] != NSOKButton) {
    return; // Abort
  }  

  NSString  *pathToScan = [[openPanel filenames] objectAtIndex: 0];
  
  NSObject <FileItemTest>  *filter = useFilter ? [self getFilter: nil] : nil;

  NSString  *fileSizeMeasure =
    [[NSUserDefaults standardUserDefaults] stringForKey: FileSizeMeasureKey];

  FreshDirViewWindowCreator  *windowCreator =
    [[FreshDirViewWindowCreator alloc] initWithWindowManager: windowManager];
  ScanTaskInput  *input = 
    [[ScanTaskInput alloc] initWithPath: pathToScan
                             fileSizeMeasure: fileSizeMeasure 
                             filterTest: filter];
    
  [scanTaskManager asynchronouslyRunTaskWithInput: input
                     callback: windowCreator
                     selector: @selector(createWindowForTree:)];
                       
  [input release];
  [windowCreator release];  
}


- (void) duplicateCurrentWindowSharingPath: (BOOL) sharePathModel {
  DirectoryViewControl  *oldControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];

  // Share or clone the path model.
  ItemPathModel  *pathModel = [[oldControl pathModelView] pathModel];

  if (!sharePathModel) {
    pathModel = [[pathModel copy] autorelease];
  }

  DirectoryViewControl  *newControl = 
    [[DirectoryViewControl alloc] 
        initWithTreeContext: [oldControl treeContext]
          pathModel: pathModel
          settings: [oldControl directoryViewControlSettings]];
  // Note: The control should auto-release itself when its window closes
    
  // Force loading (and showing) of the window.
  [windowManager addWindow:[newControl window] 
                   usingTitle:[[oldControl window] title]];
}


- (NSObject <FileItemTest> *)getFilter: (NSObject <FileItemTest> *)initialTest {
  EditFilterWindowControl  *editFilterWindowControl = 
    [[[EditFilterWindowControl alloc] init] autorelease];

  [[editFilterWindowControl window] setTitle: 
      NSLocalizedString( @"Apply filter", @"Window title" ) ];
  [editFilterWindowControl removeApplyButton];
  [editFilterWindowControl representFileItemTest: initialTest];

  ModalityTerminator  *stopModal = 
    [[[ModalityTerminator alloc] init] autorelease];
    
  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver: stopModal selector: @selector(abortModalAction:)
        name: CancelPerformedEvent object: editFilterWindowControl];
  [nc addObserver: stopModal selector: @selector(abortModalAction:)
        name: ClosePerformedEvent object: editFilterWindowControl];
        // Closing a window can be considered the same as cancelling.
  [nc addObserver: stopModal selector: @selector(stopModalAction:)
        name: OkPerformedEvent object: editFilterWindowControl];

  int  status = [NSApp runModalForWindow: [editFilterWindowControl window]];

  [nc removeObserver: stopModal];
  
  [[editFilterWindowControl window] close];

  if (status ==  NSRunAbortedResponse) {
    return nil; // Aborted
  }
  NSAssert(status == NSRunStoppedResponse, @"Unexpected status.");
  
  // Get rule from window
  return [editFilterWindowControl createFileItemTest];
}


// Creates window title based on scan location, scan time and filter (if any).
+ (NSString*) windowTitleForDirectoryView: (DirectoryViewControl *)control {
  TreeContext  *treeContext = [control treeContext];
  NSString  *scanPath = [[treeContext scanTree] path];

  NSString  *scanTimeString = 
    [[treeContext scanTime] descriptionWithCalendarFormat: @"%H:%M:%S"
                              timeZone: nil locale: nil];
  NSObject <FileItemTest>  *filter = [treeContext fileItemFilter];

  if (filter == nil) {
    return [NSString stringWithFormat: @"%@ - %@", 
                                         scanPath, scanTimeString];
  }
  else {
    return [NSString stringWithFormat: @"%@ - %@ - %@", 
                                         scanPath, scanTimeString,
                                         [filter name] ];
  }
}

@end // @implementation MainMenuControl (PrivateMethods)


@implementation ModalityTerminator

- (void) abortModalAction: (NSNotification *)notification {
  [NSApp abortModal];
}

- (void) stopModalAction: (NSNotification *)notification {
  [NSApp stopModal];
}

@end // @implementation ModalityTerminator


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
  
  // If there is a filter, ensure it has a name
  NSObject <FileItemTest>  *filter = [treeContext fileItemFilter];    
  if (filter != nil && [filter name] == nil) {
    NSString  *format = NSLocalizedString( @"Filter%d", 
                                           @"Filter naming template." );
    
    [filter setName: [NSString stringWithFormat: format, nextFilterId++]];
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

  [path suppressVisibleTreeChangedNotifications: YES];

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
      // Found the selected item. It is the path's current end point. 
      itemToSelect = [path lastFileItem];
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
    // Match the selection to that of the original path. 
    [path selectFileItem: itemToSelect];
  }
  else {
    // Did not manage to match the new path all the way up to the selected
    // item in the original path. The selected item of the new path can 
    // therefore be set to the path endpoint (as that is the closest it can 
    // come to matching the old selection).
    [path selectFileItem: [path lastFileItem]];
  }
        
  [path suppressVisibleTreeChangedNotifications: NO];

  return [[[DirectoryViewControl alloc] 
             initWithTreeContext: treeContext pathModel: path 
               settings: settings] autorelease];
}

@end // @implementation DerivedDirViewWindowCreator
