#import "MainMenuControl.h"

#import "FileItem.h"

#import "DirectoryViewControl.h"
#import "SaveImageDialogControl.h"
#import "ItemPathModel.h"

#import "WindowManager.h"

#import "AsynchronousTaskManager.h"
#import "ScanTaskExecutor.h"


@interface MainMenuControl (PrivateMethods)
- (void) createWindowForDirectory:(NSString*)dirName;
- (void) createWindowForTree:(FileItem*)itemTree;
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
  [scanTaskManager release];

  [super dealloc];
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification {
  [self openDirectoryView:self];
}

- (IBAction) openDirectoryView:(id)sender {
  NSOpenPanel  *openPanel = [NSOpenPanel openPanel];
  [openPanel setCanChooseFiles:NO];
  [openPanel setCanChooseDirectories:YES];
  [openPanel setAllowsMultipleSelection:NO];

  if ([openPanel runModalForTypes:nil] == NSOKButton) {
    NSString  *dirName = 
      [[[openPanel filenames] objectAtIndex:0] retain];
  
    [self createWindowForDirectory:dirName];
  }
}


- (BOOL) validateMenuItem:(NSMenuItem *)anItem {
  if ( [anItem action]==@selector(duplicateDirectoryView:) ||
       [anItem action]==@selector(twinDirectoryView:) ) {
    return ([[NSApplication sharedApplication] mainWindow] != nil);
  }
  
  if ( [anItem action]==@selector(saveDirectoryViewImage:) ) {
    return ([[NSApplication sharedApplication] mainWindow] != nil);
  }
  
  return YES;
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

- (void) createWindowForDirectory:(NSString*)dirName {
  [scanTaskManager asynchronouslyRunTaskWithInput:dirName callBack:self
                     selector:@selector(createWindowForTree:)];
}

- (void) createWindowForTree:(FileItem*)itemTree {
  if (itemTree == nil) {
    // Reading failed or cancelled. Don't create a window.
    return;
  }
  
  DirectoryViewControl  *dirViewControl = 
    [[DirectoryViewControl alloc] initWithItemTree:itemTree];
  // Note: The control should auto-release itself when its window closes    
      
  // Create window title based on scan location and time.
  NSString*  title = 
    [NSString stringWithFormat:@"%@ - %@", [itemTree name],
                [[NSDate date] descriptionWithCalendarFormat:@"%H:%M:%S"
                                 timeZone:nil locale:nil]];

  // Force loading (and showing) of the window.
  [windowManager addWindow:[dirViewControl window] usingTitle:title];
}


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
