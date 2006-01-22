#import "MainMenuControl.h"

#import "FileItem.h"

#import "BalancedTreeBuilder.h"
#import "DirectoryViewControl.h"
#import "SaveImageDialogControl.h"
#import "ItemPathModel.h"


@interface MainMenuControl (PrivateMethods)
- (void)readDirectories:(NSString*)dirName;
- (void)createWindowForTree:(FileItem*)itemTree;
- (void)createWindowByCopying:(BOOL)shareModel;
@end


@implementation MainMenuControl

- (id) init {
  if (self = [super init]) {
    // void
  }
  return self;
}

- (void) dealloc {
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
  
    [NSThread detachNewThreadSelector:@selector(readDirectories:)
                             toTarget:self withObject:dirName];
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

- (void) readDirectories:(NSString*)dirName {
  NSAutoreleasePool *pool;
  pool = [[NSAutoreleasePool alloc] init];
  
  NSDate  *startTime = [NSDate date];
  
  [progressText setStringValue:@"Scanning directory..."];
  [progressPanel center];
  [progressPanel orderFront:self];
  
  [progressIndicator startAnimation:nil];
  
  treeBuilder = [[BalancedTreeBuilder alloc] init];
  
  FileItem*  itemTreeRoot = [treeBuilder buildTreeForPath:dirName];
  
  [treeBuilder release];
  treeBuilder = nil;
  [dirName release];
  
  [progressIndicator stopAnimation:nil];
  NSLog(@"Done scanning. Total size=%qu, Time taken=%f", 
        [itemTreeRoot itemSize], -[startTime timeIntervalSinceNow]);
  
  [progressPanel close];
  
  if (itemTreeRoot != nil) {
    [self createWindowForTree:itemTreeRoot];
  }
  
  [pool release];  
}


- (void) createWindowForTree:(FileItem*)itemTree {
  DirectoryViewControl  *dirViewControl = 
    [[DirectoryViewControl alloc] initWithItemTree:itemTree];
  // Note: The control should auto-release itself when its window closes    
      
  // Force loading (and showing) of the window.
  [[dirViewControl window] setTitle:[itemTree name]];
}


- (void)createWindowByCopying:(BOOL)shareModel {
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
    [[newControl window] setTitle:[itemTree name]];
  }
}

@end // @implementation MainMenuControl (PrivateMethods)
