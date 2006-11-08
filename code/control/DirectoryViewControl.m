#import "DirectoryViewControl.h"

#import "DirectoryItem.h"
#import "DirectoryView.h"
#import "ItemPathModel.h"
#import "FileItemHashingOptions.h"
#import "FileItemHashing.h"
#import "ColorListCollection.h"
#import "DirectoryViewControlSettings.h"
#import "TreeHistory.h"
#import "EditFilterWindowControl.h"


@interface DirectoryViewControl (PrivateMethods)

- (void) createEditMaskFilterWindow;

- (void) updateButtonState:(NSNotification*)notification;
- (void) visibleItemTreeChanged:(NSNotification*)notification;
- (void) maskChanged;

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
      
    colorPalettes = 
      [[ColorListCollection defaultColorListCollection] retain];
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
  [colorPalettes release];
  
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
               colorPaletteKey: [colorPalettePopUp titleOfSelectedItem]
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
  
  [colorPalettePopUp removeAllItems];
  [colorPalettePopUp addItemsWithTitles: [colorPalettes allKeys]];

  [colorPalettePopUp 
    selectItemWithTitle: ( [initialSettings colorPaletteKey] != nil ?
                              [initialSettings colorPaletteKey] :
                              [colorPalettes keyForDefaultColorList] ) ];
  [self colorPaletteChanged: nil];
  
  fileItemMask = [[initialSettings fileItemMask] retain];
  [maskCheckBox setState: ( [initialSettings fileItemMaskEnabled]
                              ? NSOnState : NSOffState ) ];
  [self maskChanged];  
  
  [initialSettings release];
  initialSettings = nil;
  
  [treePathTextView setString: [[itemPathModel itemTree] name]];

  [filterNameField setStringValue: [treeHistory filterName]];
  [filterDescriptionTextView setString: 
                               ([treeHistory fileItemFilter] != nil 
                                ? [[treeHistory fileItemFilter] description]
                                : @"") ];
  
  [scanTimeField setStringValue: 
    [[treeHistory scanTime] descriptionWithCalendarFormat:@"%H:%M:%S"
                              timeZone:nil locale:nil]];
  [treeSizeField setStringValue: [FileItem exactStringForFileItemSize: 
                                    [[itemPathModel itemTree] itemSize]]];

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
  if (editMaskFilterWindowControl != nil) {
    [[editMaskFilterWindowControl window] 
        orderWindow:NSWindowBelow relativeTo:[[self window] windowNumber]];
  }
}

// Invoked because the controller is the delegate for the window.
- (void) windowWillClose:(NSNotification*)notification {
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

- (IBAction) editMask:(id)sender {
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


- (IBAction) colorPaletteChanged: (id) sender {
  [mainView setColorPalette: 
    [colorPalettes colorListForKey:
      [colorPalettePopUp titleOfSelectedItem]]];
  
}

@end // @implementation DirectoryViewControl


@implementation DirectoryViewControl (PrivateMethods)

- (void) createEditMaskFilterWindow {  
  editMaskFilterWindowControl = [[EditFilterWindowControl alloc] init];

  [editMaskFilterWindowControl setAllowEmptyFilter: YES];

  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(maskWindowApplyAction:)
        name:@"applyPerformed" object:editMaskFilterWindowControl];
  [nc addObserver:self selector:@selector(maskWindowCancelAction:)
        name:@"cancelPerformed" object:editMaskFilterWindowControl];
  [nc addObserver:self selector:@selector(maskWindowOkAction:)
        name:@"okPerformed" object:editMaskFilterWindowControl];
  // Note: the "closePerformed" notification can be ignored here.

  [nc addObserver:self selector:@selector(maskWindowDidBecomeKey:)
        name:@"NSWindowDidBecomeKeyNotification"
        object:[editMaskFilterWindowControl window]];

  [[editMaskFilterWindowControl window] setTitle: 
      NSLocalizedString( @"Edit mask", @"Window title" ) ];
}

- (void) visibleItemTreeChanged:(NSNotification*)notification {
  
  [invisiblePathName release];
  invisiblePathName = [[itemPathModel invisibleFilePathName] retain];

  [visibleFolderPathTextView setString:
    [[itemPathModel rootFilePathName] stringByAppendingPathComponent:
                                        invisiblePathName]];
  [visibleFolderSizeField setStringValue:
     [FileItem exactStringForFileItemSize: 
                 [[itemPathModel visibleItemTree] itemSize]]];

  [self updateButtonState:notification];
}


- (void) updateButtonState:(NSNotification*)notification {
  [upButton setEnabled:[itemPathModel canMoveTreeViewUp]];
  [downButton setEnabled: [itemPathModel isVisibleItemPathLocked] &&
                          [itemPathModel canMoveTreeViewDown] ];
  [openButton setEnabled: [itemPathModel isVisibleItemPathLocked] ];

  [itemSizeField setStringValue:
     [FileItem stringForFileItemSize:[[itemPathModel fileItemPathEndPoint] 
                                                       itemSize]]];

  NSString  *visiblePathName = [itemPathModel visibleFilePathName];

  if ( [visiblePathName length] > 0) {
    NSString  *name = [invisiblePathName stringByAppendingPathComponent:
                         visiblePathName];
    NSMutableAttributedString  *attributedName = 
      [[NSMutableAttributedString alloc] initWithString: name];
   
    // Mark invisible part of path
    int  invisLen = [invisiblePathName length];
    [attributedName addAttribute: NSForegroundColorAttributeName
                      value: [NSColor darkGrayColor] 
                      range: NSMakeRange(invisLen, [name length] - invisLen) ];
    [itemPathField setStringValue: ((id) attributedName) ];

    [attributedName release];
  }
  else {
    // There's no visible part, so can directly use "invisiblePathName"
    [itemPathField setStringValue: invisiblePathName];
  }
  
  [selectedFilePathTextView setString:
    [[visibleFolderPathTextView string] stringByAppendingPathComponent:
                                          visiblePathName]];
  [selectedFileSizeField setStringValue: 
     [FileItem exactStringForFileItemSize: 
                 [[itemPathModel fileItemPathEndPoint] itemSize]]];
}


- (void) maskChanged {
  if (fileItemMask != nil) {
    [maskCheckBox setEnabled: YES];
    [maskDescriptionTextView setString: [fileItemMask description]];
  }
  else {
    [maskDescriptionTextView setString: @""];
    [maskCheckBox setEnabled: NO];
    [maskCheckBox setState: NSOffState];
  }
  
  [mainView setFileItemMask: 
              (([maskCheckBox state] == NSOnState) ? fileItemMask : nil) ];
}


- (void) maskWindowApplyAction:(NSNotification*)notification {
  [fileItemMask release];
  
  fileItemMask = [[editMaskFilterWindowControl createFileItemTest] retain];

  if (fileItemMask != nil) {
    // Automatically enable mask.
    [maskCheckBox setState: NSOnState];
  }
  
  [self maskChanged];
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
  [[self window] orderWindow:NSWindowBelow
               relativeTo:[[editMaskFilterWindowControl window] windowNumber]];
  [[self window] makeMainWindow];
}

@end // @implementation DirectoryViewControl (PrivateMethods)
