#import "DirectoryViewControl.h"

#import "DirectoryItem.h"
#import "DirectoryView.h"
#import "ItemPathModel.h"
#import "FileItemHashingOptions.h"
#import "FileItemHashing.h"
#import "DirectoryViewControlSettings.h"
#import "TreeHistory.h"
#import "EditFilterWindowControl.h"


@interface DirectoryViewControl (PrivateMethods)

- (void) createEditMaskFilterWindow;

- (void) updateButtonState:(NSNotification*)notification;
- (void) visibleItemTreeChanged:(NSNotification*)notification;

- (void) maskWindowApplyAction:(NSNotification*)notification;
- (void) maskWindowCancelAction:(NSNotification*)notification;
- (void) maskWindowOkAction:(NSNotification*)notification;
- (void) maskWindowDidBecomeKey:(NSNotification*)notification;

@end


@implementation DirectoryViewControl

- (id) initWithItemTree: (DirectoryItem *)itemTreeRoot {
  ItemPathModel  *pathModel = 
    [[[ItemPathModel alloc] initWithTree:itemTreeRoot] autorelease];

  // Default settings
  DirectoryViewControlSettings  *defaultSettings =
    [[[DirectoryViewControlSettings alloc] init] autorelease];

  TreeHistory  *defaultHistory = [[[TreeHistory alloc] init] autorelease];

  return [self initWithItemPathModel: pathModel 
                 history: defaultHistory
                 settings: defaultSettings];
}

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) initWithItemPathModel: (ItemPathModel *)itemPathModelVal
         history: (TreeHistory *)history
         settings: (DirectoryViewControlSettings *)settings {
  if (self = [super initWithWindowNibName:@"DirectoryViewWindow" owner:self]) {
    itemPathModel = [itemPathModelVal retain];
    initialSettings = [settings retain];
    treeHistory = [history retain];

    invisiblePathName = nil;    
    hashingOptions = 
      [[FileItemHashingOptions defaultFileItemHashingOptions] retain];
  }

  return self;
}


- (void) dealloc {
  NSLog(@"DirectoryViewControl-dealloc");

  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [itemPathModel release];
  [initialSettings release];
  [treeHistory release];
  
  [fileItemMask release];
  
  [hashingOptions release];
  
  [editMaskFilterWindowControl release];

  [invisiblePathName release];
  
  [super dealloc];
}


- (FileItemHashing*) fileItemHashing {
  return [mainView fileItemHashing];
}

- (NSObject <FileItemTest> *) fileItemMask {
  return fileItemMask;
}

- (BOOL) fileItemMaskEnabled {
  return [mainView fileItemMask] != nil;
}

- (ItemPathModel*) itemPathModel {
  return itemPathModel;
}

- (DirectoryView*) directoryView {
  return mainView;
}

- (DirectoryViewControlSettings*) directoryViewControlSettings {
  return [[[DirectoryViewControlSettings alloc]
               initWithHashingKey: [colorMappingPopUp titleOfSelectedItem]
               mask: fileItemMask
               maskEnabled: [self fileItemMaskEnabled]] 
                 autorelease];
}

- (TreeHistory*) treeHistory {
  return treeHistory;
}


- (void) windowDidLoad {
  [mainView setItemPathModel:itemPathModel];

  [colorMappingPopUp removeAllItems];
  [colorMappingPopUp addItemsWithTitles:
     [[hashingOptions allKeys] 
         sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
  
  [colorMappingPopUp 
     selectItemWithTitle: ( [initialSettings fileItemHashingKey] != nil ?
                              [initialSettings fileItemHashingKey] :
                              [hashingOptions keyForDefaultHashing] ) ];
  [self colorMappingChanged:nil];
  
  fileItemMask = [[initialSettings fileItemMask] retain];
  if ([initialSettings fileItemMaskEnabled]) {
    [mainView setFileItemMask:fileItemMask];
  }
  [initialSettings release];
  initialSettings = nil;
  
  [treePathTextView setString: [[itemPathModel itemTree] name]];

  if ( [treeHistory fileItemFilter] != nil ) {
    [filterNameField setStringValue: [NSString stringWithFormat: @"Filter%d",
                                        [treeHistory filterIdentifier]]];
    [filterDescriptionTextView setString:
       [[treeHistory fileItemFilter] description]];
  }
  else {
    [filterNameField setStringValue: @"None"];
    [filterDescriptionTextView setString: @""];
  }
  
  [scanTimeField setStringValue: 
    [[treeHistory scanTime] descriptionWithCalendarFormat:@"%H:%M:%S"
                              timeZone:nil locale:nil]];
  [treeSizeField setStringValue: [NSString stringWithFormat: @"%qu bytes", 
                                    [[itemPathModel itemTree] itemSize]]];

  NSSize  drawerSize = NSMakeSize(301, 337);
  [drawer setContentSize: drawerSize];  
  [drawer setMinContentSize: drawerSize];
  [drawer setMaxContentSize: drawerSize];

  [super windowDidLoad];
  
  NSAssert(invisiblePathName == nil, @"invisiblePathName unexpectedly set.");
  invisiblePathName = [[itemPathModel invisibleFilePathName] retain];

  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(updateButtonState:)
        name:@"visibleItemPathChanged" object:itemPathModel];
  [nc addObserver:self selector:@selector(updateButtonState:)
        name:@"visibleItemPathLockingChanged" object:itemPathModel];
  [nc addObserver:self selector:@selector(visibleItemTreeChanged:)
        name:@"visibleItemTreeChanged" object:itemPathModel];

  [self visibleItemTreeChanged: nil];

  [[self window] makeFirstResponder:mainView];
  [[self window] makeKeyAndOrderFront:self];
}

// Invoked because the controller is the delegate for the window.
- (void) windowDidBecomeMain:(NSNotification*)notification {
  NSLog(@"windowDidBecomeMain %@", [[self window] title]);
  
  if (editMaskFilterWindowControl != nil) {
    [[editMaskFilterWindowControl window] 
        orderWindow:NSWindowBelow relativeTo:[[self window] windowNumber]];
  }
}

// Invoked because the controller is the delegate for the window.
- (void) windowWillClose:(NSNotification*)notification {
  NSLog(@"windowWillClose");
  [self autorelease];
}

- (IBAction) upAction:(id)sender {
  [itemPathModel moveTreeViewUp];
  
  // Automatically lock path as well.
  [itemPathModel setVisibleItemPathLocking:YES];
}

- (IBAction) downAction:(id)sender {
  [itemPathModel moveTreeViewDown];
}

- (IBAction) openFileInFinder:(id)sender {
  NSString  *filePath = [itemPathModel visibleFilePathName];
  NSString  *rootPath = 
    [[itemPathModel rootFilePathName] 
      stringByAppendingPathComponent: [itemPathModel invisibleFilePathName]];
    
  NSLog(@"root=%@ file=%@", rootPath, filePath);

  [[NSWorkspace sharedWorkspace] 
    selectFile: [rootPath stringByAppendingPathComponent:filePath] 
    inFileViewerRootedAtPath: rootPath];  
}


- (IBAction) maskCheckBoxChanged:(id)sender {
  if ( [sender state]==NSOnState ) {
    [mainView setFileItemMask:fileItemMask];
  }
  else {
    [mainView setFileItemMask:nil];
  }
}

- (IBAction) maskAction:(id)sender {
  if (editMaskFilterWindowControl == nil) {
    // Lazily create the "edit mask" window.
    
    [self createEditMaskFilterWindow];
  }
  
  [editMaskFilterWindowControl representFileItemTest:fileItemMask];

  // Note: First order it to front, then make it key. This ensures that
  // the maskWindowDidBecomeKey: does not move the DirectoryViewWindow to
  // the back.
  [[editMaskFilterWindowControl window] orderFront:self];
  [[editMaskFilterWindowControl window] makeKeyWindow];
}

- (IBAction) colorMappingChanged:(id)sender {
  [mainView setFileItemHashing: 
    [hashingOptions fileItemHashingForKey:
      [colorMappingPopUp titleOfSelectedItem]]];
}

@end // @implementation DirectoryViewControl


@implementation DirectoryViewControl (PrivateMethods)

- (void) createEditMaskFilterWindow {  
  editMaskFilterWindowControl = [[EditFilterWindowControl alloc] init];
    
  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(maskWindowApplyAction:)
        name:@"applyPerformed" object:editMaskFilterWindowControl];
  [nc addObserver:self selector:@selector(maskWindowCancelAction:)
        name:@"cancelPerformed" object:editMaskFilterWindowControl];
  [nc addObserver:self selector:@selector(maskWindowOkAction:)
        name:@"okPerformed" object:editMaskFilterWindowControl];

  [nc addObserver:self selector:@selector(maskWindowDidBecomeKey:)
        name:@"NSWindowDidBecomeKeyNotification"
        object:[editMaskFilterWindowControl window]];
                  
  [[editMaskFilterWindowControl window] setTitle:@"Edit mask"];
}

- (void) visibleItemTreeChanged:(NSNotification*)notification {
  
  [invisiblePathName release];
  invisiblePathName = [[itemPathModel invisibleFilePathName] retain];

  [visibleFolderPathTextView setString:
    [[itemPathModel rootFilePathName] stringByAppendingPathComponent:
                                        invisiblePathName]];
  [visibleFolderSizeField setStringValue:
    [NSString stringWithFormat: @"%qu bytes", 
                [[itemPathModel visibleItemTree] itemSize]]];

  [self updateButtonState:notification];
}


- (void) updateButtonState:(NSNotification*)notification {
  [upButton setEnabled:[itemPathModel canMoveTreeViewUp]];
  [downButton setEnabled: [itemPathModel isVisibleItemPathLocked] &&
                          [itemPathModel canMoveTreeViewDown] ];
  [openButton setEnabled: [itemPathModel isVisibleItemPathLocked] ];

  [itemSizeLabel setStringValue:
     [FileItem stringForFileItemSize:[[itemPathModel fileItemPathEndPoint] 
                                                       itemSize]]];

  NSString  *visiblePathName = [itemPathModel visibleFilePathName];
  
  NSMutableString  *name = 
    [[NSMutableString alloc] 
        initWithCapacity:[invisiblePathName length] +
                         [visiblePathName length] + 32];
  [name appendString:invisiblePathName];

  int  visibleStartPos = 0;
  if ([visiblePathName length] > 0) {
    if ([name length] > 0) {
      [name appendString:@"/"];
    }
    visibleStartPos = [name length];
    [name appendString:visiblePathName];
  }

  id  attributedName = [[NSMutableAttributedString alloc] initWithString:name];
   
  if ([visiblePathName length] > 0) {
    // Mark invisible part of path
    [attributedName addAttribute:NSForegroundColorAttributeName
      value:[NSColor darkGrayColor] 
      range:NSMakeRange(visibleStartPos, [name length] - visibleStartPos)];
  }
    
  [itemNameLabel setStringValue:attributedName];
  
  [selectedFilePathTextView setString:
    [[visibleFolderPathTextView string] stringByAppendingPathComponent:
                                          visiblePathName]];
  [selectedFileSizeField setStringValue: 
     [NSString stringWithFormat: @"%qu bytes", 
                [[itemPathModel fileItemPathEndPoint] itemSize]]];

  [name release];
  [attributedName release]; 
}


- (void) maskWindowApplyAction:(NSNotification*)notification {
  [fileItemMask release];
  
  fileItemMask = [[editMaskFilterWindowControl createFileItemTest] retain];
  
  if (fileItemMask != nil) {
    // Automatically enable mask (doesn't matter if it's already enabled).
    [maskCheckBox setState:NSOnState];
  }
  [mainView setFileItemMask:fileItemMask];
}

- (void) maskWindowCancelAction:(NSNotification*)notification {
  [[editMaskFilterWindowControl window] close];
}

- (void) maskWindowOkAction:(NSNotification*)notification {
  [[editMaskFilterWindowControl window] close];
  
  // Other than closing the window, the action is same as the "apply" one.
  [self maskWindowApplyAction:notification];
}

- (void) maskWindowDidBecomeKey:(NSNotification*)notification {
  NSLog(@"maskWindowDidBecomeKey");
  [[self window] orderWindow:NSWindowBelow
               relativeTo:[[editMaskFilterWindowControl window] windowNumber]];
  [[self window] makeMainWindow];
}

@end // @implementation DirectoryViewControl (PrivateMethods)
