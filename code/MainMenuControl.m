#import "MainMenuControl.h"

#import "FileItem.h"

#import "DirectoryViewControl.h"
#import "SaveImageDialogControl.h"
#import "ItemPathModel.h"

#import "WindowManager.h"

#import "AsynchronousTaskManager.h"
#import "ScanTaskExecutor.h"


@interface PostScanningWindowCreator : NSObject {
  WindowManager  *windowManager;
  NSArray  *invisibleFileItemTargetPath; 
  NSArray  *visibleFileItemTargetPath;
}

- (id) initWithWindowManager:(WindowManager*)windowManager;
- (id) initWithWindowManager:(WindowManager*)windowManager 
          targetPath:(ItemPathModel*)targetPath;

- (void) createWindowForTree:(FileItem*)itemTree;

@end


@interface MainMenuControl (PrivateMethods)
- (void) createWindowByCopying:(BOOL)shareModel;
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
       [anItem action]==@selector(rescanDirectoryView:) ) {
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
    
    PostScanningWindowCreator  *windowCreator =
      [[PostScanningWindowCreator alloc] initWithWindowManager:windowManager];
      
    [scanTaskManager asynchronouslyRunTaskWithInput:dirName 
                       callBack:windowCreator
                       selector:@selector(createWindowForTree:)];
                       
    [windowCreator release];
  }
}


- (IBAction) rescanDirectoryView:(id)sender {
  DirectoryViewControl  *oldControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];

  ItemPathModel  *itemPathModel = [oldControl itemPathModel];

  if (itemPathModel != nil) {
    NSString  *dirName = [itemPathModel rootFilePathName];
    
    PostScanningWindowCreator  *windowCreator =
      [[PostScanningWindowCreator alloc] 
          initWithWindowManager:windowManager targetPath:itemPathModel];
          
    [scanTaskManager asynchronouslyRunTaskWithInput:dirName 
                       callBack:windowCreator
                       selector:@selector(createWindowForTree:)];
                       
    [windowCreator release];
  }
}


- (IBAction) duplicateDirectoryView:(id)sender {
  [self createWindowByCopying:NO];
}

- (IBAction) twinDirectoryView:(id)sender {
  [self createWindowByCopying:YES];
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

- (void) createWindowByCopying:(BOOL)shareModel {
  DirectoryViewControl  *oldControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];
  FileItem  *itemTree = [oldControl itemTree];
  
  if (itemTree!=nil) {
    NSString  *fileItemHashingKey = [oldControl fileItemHashingKey];

    // Share or clone the path model.
    ItemPathModel  *itemPathModel = [oldControl itemPathModel];
    if (!shareModel) {
      itemPathModel = [[itemPathModel copy] autorelease];
    }
    
    DirectoryViewControl  *newControl = 
      [[DirectoryViewControl alloc] 
          initWithItemTree:itemTree 
          itemPathModel:itemPathModel
          fileItemHashingKey:fileItemHashingKey];          
    // Note: The control should auto-release itself when its window closes
      
    // Force loading (and showing) of the window.
    [windowManager addWindow:[newControl window] 
                     usingTitle:[[oldControl window] title]];
  }
}

@end // @implementation MainMenuControl (PrivateMethods)


@implementation PostScanningWindowCreator

// Overrides designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithWindowManager: instead.");
}

- (id) initWithWindowManager:(WindowManager*)windowManagerVal {
  return [self initWithWindowManager:windowManagerVal targetPath:nil];
}

- (id) initWithWindowManager:(WindowManager*)windowManagerVal 
          targetPath:(ItemPathModel*)targetPath {
  if (self = [super init]) {
    windowManager = [windowManagerVal retain];
    
    if (targetPath != nil) {
      invisibleFileItemTargetPath = [[targetPath invisibleFileItemPath] retain];
      visibleFileItemTargetPath = [[targetPath visibleFileItemPath] retain];
    }
  }
  return self;
}

- (void) dealloc {
  NSLog(@"PostScanningWindowCreator dealloc");
  
  [invisibleFileItemTargetPath release];
  [visibleFileItemTargetPath release];
  [windowManager release];
  
  [super dealloc];
}

- (void) createWindowForTree:(FileItem*)itemTree {
  if (itemTree == nil) {
    // Reading failed or cancelled. Don't create a window.
    return;
  }
  
  DirectoryViewControl  *dirViewControl = 
    [[DirectoryViewControl alloc] initWithItemTree:itemTree];
  // Note: The control should auto-release itself when its window closes
  
  if (invisibleFileItemTargetPath != nil) {
    // Try to match the path.
    
    ItemPathModel  *path = [dirViewControl itemPathModel];
    [path suppressItemPathChangedNotifications:YES];
    
    BOOL  ok = YES;
    NSEnumerator  *fileItemEnum = 
      [invisibleFileItemTargetPath objectEnumerator];
    FileItem  *fileItem;
    
    [fileItemEnum nextObject]; // Skip the root.
    while (ok && (fileItem = [fileItemEnum nextObject])) {
      ok = [path extendVisibleItemPathToFileItemWithName:[fileItem name]];
    }
    // Make this extension "invisible".
    while ([path canMoveTreeViewDown]) {
      [path moveTreeViewDown];
    }
    
    if (ok && visibleFileItemTargetPath != nil) {
      fileItemEnum = [visibleFileItemTargetPath objectEnumerator];
      while (ok && (fileItem = [fileItemEnum nextObject])) {
        ok = [path extendVisibleItemPathToFileItemWithName:[fileItem name]];
      }
    }
        
    [path suppressItemPathChangedNotifications:NO];
    [path setVisibleItemPathLocking:YES];
  }
  
  // Create window title based on scan location and time.
  NSString*  title = 
    [NSString stringWithFormat:@"%@ - %@", [itemTree name],
                [[NSDate date] descriptionWithCalendarFormat:@"%H:%M:%S"
                                 timeZone:nil locale:nil]];

  // Force loading (and showing) of the window.
  [windowManager addWindow:[dirViewControl window] usingTitle:title];
}

@end // @implementation PostScanningWindowCreator

