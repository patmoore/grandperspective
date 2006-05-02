#import "MainMenuControl.h"

#import "FileItem.h"

#import "BalancedTreeBuilder.h"
#import "DirectoryViewControl.h"
#import "SaveImageDialogControl.h"
#import "ItemPathModel.h"

#import "WindowManager.h"


// TODO: Move it to its own file. Make it own the progressPanel, -Text and
// -Indicator. And also make it responsible for handling abort.
@interface ScanDirectoryInvocation : NSObject {
  id        callBack;
  SEL       callBackSelector;
}

- (id) initWithCallBack:(id)callBack selector:(SEL)selector;

// Can be invoked in a different thread
- (void) scanDirectory:(NSString*)dirName;

@end


@interface MainMenuControl (PrivateMethods)
- (void) createWindowForDirectory:(NSString*)dirName;
- (void) createWindowForTree:(FileItem*)itemTree;
- (void) createWindowByCopying:(BOOL)shareModel;
@end


@implementation MainMenuControl

- (id) init {
  if (self = [super init]) {
    windowManager = [[WindowManager alloc] init];
  }
  return self;
}

- (void) dealloc {
  [windowManager release];

  NSAssert(treeBuilder == nil, @"TreeBuilder should be nil.");
  
  [super dealloc];
}

- (IBAction) abort:(id)sender {
  [treeBuilder abort];
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


@implementation ScanDirectoryInvocation

- (id) initWithCallBack:(id)callBackVal selector:(SEL)selector {
  if (self = [super init]) {
    callBack = [callBackVal retain];
    callBackSelector = selector;
  }
}

- (void) dealloc {
  [super dealloc];
  
  [callBack release];
}


// Designed to be invoked in a separate thread.
- (void) scanDirectory:(NSString*)dirName {
  NSAutoreleasePool *pool;
  pool = [[NSAutoreleasePool alloc] init];
  
  NSDate  *startTime = [NSDate date];
  
  [progressText setStringValue:[NSString stringWithFormat:@"Scanning %@", 
                                           dirName]];
  [progressPanel center];
  [progressPanel orderFront:self];
  
  [progressIndicator startAnimation:nil];
  
  treeBuilder = [[BalancedTreeBuilder alloc] init];
  
  FileItem*  itemTreeRoot = [treeBuilder buildTreeForPath: [self dirName]];
  
  [treeBuilder release];
  treeBuilder = nil;
  [dirName release];
  
  [progressIndicator stopAnimation:nil];
  NSLog(@"Done scanning. Total size=%qu, Time taken=%f", 
        [itemTreeRoot itemSize], -[startTime timeIntervalSinceNow]);
  
  [progressPanel close];
 
  [callBack performSelector:callBackSelector withObject:itemTreeRoot];
  
  [pool release];  
}

@end // @implementation ScanDirectoryInvocation


@implementation MainMenuControl (PrivateMethods)

- (void) createWindowForDirectory:(NSString*)dirName {
  ScanDirectoryInvocation  scanner = 
    [[ScanDirectoryInvocation alloc] initWithCallBack:self 
                                    selector:@selector(createWindowForTree:)];
                                    
  [NSThread detachNewThreadSelector:@selector(scanDirectory:)
              toTarget:scanner withObject:dirName];
                    
  // Assumes that above call retains its target.
  [scanner release];
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
