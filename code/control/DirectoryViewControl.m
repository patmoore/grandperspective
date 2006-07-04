#import "DirectoryViewControl.h"

#import "DirectoryItem.h"
#import "DirectoryView.h"
#import "ItemPathModel.h"
#import "FileItemHashingOptions.h"
#import "FileItemHashing.h"

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

- (id) initWithItemTree:(DirectoryItem*)root {
  ItemPathModel  *pathModel = 
    [[[ItemPathModel alloc] initWithTree:root] autorelease];

  return [self initWithItemTree:root 
                 itemPathModel:pathModel
                 fileItemHashingKey:nil];
}

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) initWithItemTree:(DirectoryItem*)root 
         itemPathModel:(ItemPathModel*)pathModel
         fileItemHashingKey:(NSString*)fileItemHashingKey {
         
  if (self = [super initWithWindowNibName:@"DirectoryViewWindow" owner:self]) {
    itemTreeRoot = [root retain];
    invisiblePathName = nil;
    
    hashingOptions = 
      [[FileItemHashingOptions defaultFileItemHashingOptions] retain];
    
    initialHashingOptionKey = 
      [ ((fileItemHashingKey == nil) ? [hashingOptions keyForDefaultHashing]
                                     : fileItemHashingKey) 
        retain ];
    
    itemPathModel = [pathModel retain];
  }

  return self;
}

- (void) dealloc {
  NSLog(@"DirectoryViewControl-dealloc");

  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [editMaskFilterWindowControl release];

  [itemTreeRoot release];
  [itemPathModel release];
  
  [invisiblePathName release];
  
  [fileItemMask release];

  [hashingOptions release];
  [initialHashingOptionKey release];
  
  [super dealloc];
}


- (DirectoryItem*) itemTree {
  return itemTreeRoot;
}


- (NSString*) fileItemHashingKey {
  return [colorMappingPopUp titleOfSelectedItem];
}

- (FileItemHashing*) fileItemHashing {
  return [mainView fileItemHashing];
}


- (NSObject <FileItemTest> *) fileItemMask {
  return fileItemMask;
}

- (void) setFileItemMask:(NSObject <FileItemTest> *) mask {
  if (mask != fileItemMask) {
    [fileItemMask release];
    fileItemMask = [mask retain];

    if ([mainView fileItemMask] != nil) {
      // Only let mainview immediately use it if it was already using a mask.
      [mainView setFileItemMask:fileItemMask];
    }
  }
}


- (BOOL) fileItemMaskEnabled {
  return [mainView fileItemMask] != nil;
}

- (void) enableFileItemMask:(BOOL) flag {
  if (flag) {
    [maskCheckBox setState:NSOnState];

    [mainView setFileItemMask:fileItemMask];
  }
  else {
    [maskCheckBox setState:NSOffState];

    [mainView setFileItemMask:nil];    
  }
}


- (ItemPathModel*) itemPathModel {
  return itemPathModel;
}


- (DirectoryView*) directoryView {
  return mainView;
}


- (void) windowDidLoad {
  [colorMappingPopUp removeAllItems];
  [colorMappingPopUp addItemsWithTitles:
     [[hashingOptions allKeys] 
         sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
  
  [colorMappingPopUp selectItemWithTitle:initialHashingOptionKey];
  [initialHashingOptionKey release];
  initialHashingOptionKey = nil;
  [self colorMappingChanged:nil];
  
  [mainView setItemPathModel:itemPathModel];
  
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

  [self updateButtonState:nil];

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
  FileItemHashing  *hashingOption = 
    [hashingOptions fileItemHashingForKey:
                               [colorMappingPopUp titleOfSelectedItem]];
      
  [mainView setFileItemHashing:hashingOption];
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
