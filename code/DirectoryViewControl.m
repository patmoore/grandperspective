#import "DirectoryViewControl.h"

#import "FileItem.h"
#import "DirectoryView.h"
#import "ItemPathModel.h"
#import "FileItemHashingOptions.h"
#import "FileItemHashing.h"

#import "EditFilterWindowControl.h"


@interface DirectoryViewControl (PrivateMethods)

- (void) updateButtonState:(NSNotification*)notification;
- (void) visibleItemTreeChanged:(NSNotification*)notification;

- (void) maskWindowApplyAction:(NSNotification*)notification;
- (void) maskWindowCancelAction:(NSNotification*)notification;
- (void) maskWindowOkAction:(NSNotification*)notification;
- (void) maskWindowClosingAction:(NSNotification*)notification;
- (void) maskWindowDidBecomeKey:(NSNotification*)notification;

@end


@implementation DirectoryViewControl

- (id) initWithItemTree:(FileItem*)root {
  ItemPathModel  *pathModel = 
    [[[ItemPathModel alloc] initWithTree:root] autorelease];

  return [self initWithItemTree:root 
                 itemPathModel:pathModel
                 fileItemHashingKey:nil];
}

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) initWithItemTree:(FileItem*)root 
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

  [hashingOptions release];
  [initialHashingOptionKey release];
  
  [super dealloc];
}


- (FileItem*) itemTree {
  return itemTreeRoot;
}


- (NSString*) fileItemHashingKey {
  return [colorMappingChoice objectValueOfSelectedItem];
}

- (FileItemHashing*) fileItemHashing {
  return [mainView fileItemHashing];
}


- (ItemPathModel*) itemPathModel {
  return itemPathModel;
}


- (DirectoryView*) directoryView {
  return mainView;
}


- (EditFilterWindowControl*) editMaskFilterWindowControl {
  return editMaskFilterWindowControl;
}


- (void) windowDidLoad {
  [colorMappingChoice addItemsWithObjectValues:
     [[hashingOptions allKeys] 
         sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
  
  [colorMappingChoice selectItemWithObjectValue:initialHashingOptionKey];
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

- (IBAction) maskAction:(id)sender {
  if (editMaskFilterWindowControl == nil) {
    // Lazily create the "edit mask" window.
    
    editMaskFilterWindowControl = [[EditFilterWindowControl alloc] init];
    
    NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(maskWindowApplyAction:)
          name:@"applyPerformed" object:editMaskFilterWindowControl];
    [nc addObserver:self selector:@selector(maskWindowCancelAction:)
          name:@"cancelPerformed" object:editMaskFilterWindowControl];
    [nc addObserver:self selector:@selector(maskWindowOkAction:)
          name:@"okPerformed" object:editMaskFilterWindowControl];

    [nc addObserver:self selector:@selector(maskWindowClosingAction:)
          name:@"NSWindowWillCloseNotification" 
          object:[editMaskFilterWindowControl window]];
    [nc addObserver:self selector:@selector(maskWindowDidBecomeKey:)
          name:@"NSWindowDidBecomeKeyNotification"
          object:[editMaskFilterWindowControl window]];
                  
    [[editMaskFilterWindowControl window] setTitle:@"Edit mask"];
  }

  // Note: First order it to front, then make it key. This ensures that
  // the maskWindowDidBecomeKey: does not move the DirectoryViewWindow to
  // the back.
  [[editMaskFilterWindowControl window] orderFront:self];
  [[editMaskFilterWindowControl window] makeKeyWindow];
}

- (IBAction) colorMappingChanged:(id)sender {
  FileItemHashing  *hashingOption = 
    [hashingOptions fileItemHashingForKey:
                               [colorMappingChoice objectValueOfSelectedItem]];
      
  [mainView setFileItemHashing:hashingOption];
}

@end // @implementation DirectoryViewControl


@implementation DirectoryViewControl (PrivateMethods)

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
  NSLog(@"applyMask");
  
  [mainView setFileItemMask: [editMaskFilterWindowControl createFileItemTest]];
}

- (void) maskWindowCancelAction:(NSNotification*)notification {
  NSLog(@"cancelMask");
  
  [[editMaskFilterWindowControl window] close];
}

- (void) maskWindowOkAction:(NSNotification*)notification {
  NSLog(@"okMask");

  [[editMaskFilterWindowControl window] close];
  
  [mainView setFileItemMask: [editMaskFilterWindowControl createFileItemTest]];
}

- (void) maskWindowClosingAction:(NSNotification*)notification {
  NSLog(@"closingMask");
}

- (void) maskWindowDidBecomeKey:(NSNotification*)notification {
  [[self window] orderWindow:NSWindowBelow
               relativeTo:[[editMaskFilterWindowControl window] windowNumber]];
}

@end // @implementation DirectoryViewControl (PrivateMethods)
