#import "DirectoryViewControl.h"

#import "DirectoryItem.h"
#import "DirectoryView.h"
#import "ItemPathModel.h"
#import "FileItemHashingCollection.h"
#import "ColorListCollection.h"
#import "DirectoryViewControlSettings.h"
#import "TreeHistory.h"
#import "TreeBuilder.h"
#import "EditFilterWindowControl.h"
#import "ItemTreeDrawerSettings.h"


@interface DirectoryViewControl (PrivateMethods)
                   
- (void) createEditMaskFilterWindow;

- (void) updateButtonState:(NSNotification*)notification;
- (void) visibleTreeChanged:(NSNotification*)notification;
- (void) maskChanged;
- (void) updateMask;

- (void) maskWindowApplyAction:(NSNotification*)notification;
- (void) maskWindowCancelAction:(NSNotification*)notification;
- (void) maskWindowOkAction:(NSNotification*)notification;
- (void) maskWindowDidBecomeKey:(NSNotification*)notification;

@end


@implementation DirectoryViewControl

- (id) initWithTreeHistory: (TreeHistory *)history {
  ItemPathModel  *pathModel = 
    [[[ItemPathModel alloc] initWithVolumeTree: [history volumeTree]] 
         autorelease];

  // Default settings
  DirectoryViewControlSettings  *defaultSettings =
    [[[DirectoryViewControlSettings alloc] init] autorelease];

  return [self initWithTreeHistory: history
                 pathModel: pathModel 
                 settings: defaultSettings];
}


// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) initWithTreeHistory: (TreeHistory *)treeHistoryVal
         pathModel: (ItemPathModel *)itemPathModelVal
         settings: (DirectoryViewControlSettings *)settings {
  if (self = [super initWithWindowNibName:@"DirectoryViewWindow" owner:self]) {
    NSAssert([itemPathModelVal volumeTree] == [treeHistoryVal volumeTree], 
               @"Tree mismatch");
    treeHistory = [treeHistoryVal retain];
    itemPathModel = [itemPathModelVal retain];
    initialSettings = [settings retain];

    DirectoryItem  *scanTree = 
      [TreeBuilder scanTreeOfVolume: [itemPathModel volumeTree]];
    rootPathName = [[scanTree stringForFileItemPath] retain];
    
    invisiblePathName = nil;
       
    colorMappings = 
      [[FileItemHashingCollection defaultFileItemHashingCollection] retain];
    colorPalettes = 
      [[ColorListCollection defaultColorListCollection] retain];
  }

  return self;
}


- (void) dealloc {
  NSLog(@"DirectoryViewControl-dealloc");

  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [treeHistory release];
  [itemPathModel release];
  [initialSettings release];
  
  [fileItemMask release];
  
  [colorMappings release];
  [colorPalettes release];
  
  [localizedColorMappingNamesReverseLookup release];
  [localizedColorPaletteNamesReverseLookup release];
  
  [editMaskFilterWindowControl release];

  [rootPathName release];
  [invisiblePathName release];
  
  [super dealloc];
}


- (NSObject <FileItemTest> *) fileItemMask {
  return fileItemMask;
}

- (ItemPathModel*) itemPathModel {
  return itemPathModel;
}

- (DirectoryView*) directoryView {
  return mainView;
}

- (DirectoryViewControlSettings*) directoryViewControlSettings {
  NSString  *colorMappingKey = 
    [localizedColorMappingNamesReverseLookup 
       objectForKey: [colorMappingPopUp titleOfSelectedItem]];
  NSString  *colorPaletteKey = 
    [localizedColorPaletteNamesReverseLookup
       objectForKey: [colorPalettePopUp titleOfSelectedItem]];

  return [[[DirectoryViewControlSettings alloc]
              initWithColorMappingKey: colorMappingKey
              colorPaletteKey: colorPaletteKey
              mask: fileItemMask
              maskEnabled: [maskCheckBox state]==NSOnState
              showEntireVolume: [showEntireVolumeCheckBox state]==NSOnState]
                autorelease];
}

- (TreeHistory*) treeHistory {
  return treeHistory;
}


- (void) windowDidLoad {
  [mainView postInitWithPathModel: itemPathModel];

  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  NSBundle  *mainBundle = [NSBundle mainBundle];
  
  [colorMappingPopUp removeAllItems];  
  NSString  *selectedMappingName = 
    ( [initialSettings colorMappingKey] != nil ?
         [initialSettings colorMappingKey] :
         [userDefaults stringForKey: @"defaultColorMapping"] );
  localizedColorMappingNamesReverseLookup =
    [[DirectoryViewControl
        addLocalisedNamesToPopUp: colorMappingPopUp
        names: [colorMappings allKeys]
        selectName: selectedMappingName 
        table: @"Names"] retain];
  [self colorMappingChanged: nil];
  
  [colorPalettePopUp removeAllItems];
  NSString  *selectedPaletteName =
    ( [initialSettings colorPaletteKey] != nil ?
         [initialSettings colorPaletteKey] :
         [userDefaults stringForKey: @"defaultColorPalette"] );
  localizedColorPaletteNamesReverseLookup =
    [[DirectoryViewControl
        addLocalisedNamesToPopUp: colorPalettePopUp
        names: [colorPalettes allKeys]
        selectName: selectedPaletteName  
        table: @"Names"] retain];
  [self colorPaletteChanged: nil];
  
  fileItemMask = [[initialSettings fileItemMask] retain];
  [maskCheckBox setState: ( [initialSettings fileItemMaskEnabled]
                              ? NSOnState : NSOffState ) ];
  [self maskChanged];
  
  [showEntireVolumeCheckBox setState: 
     ( [initialSettings showEntireVolume] ? NSOnState : NSOffState ) ];
  [self showEntireVolumeCheckBoxChanged: nil];
  
  [initialSettings release];
  initialSettings = nil;
  
  FileItem  *visibleTree = [itemPathModel visibleTree];
  [treePathTextView setString: [visibleTree stringForFileItemPath]];

  [filterNameField setStringValue: [treeHistory filterName]];
  [filterDescriptionTextView setString: 
                               ([treeHistory fileItemFilter] != nil 
                                ? [[treeHistory fileItemFilter] description]
                                : @"") ];
  
  [scanTimeField setStringValue: 
    [[treeHistory scanTime] descriptionWithCalendarFormat:@"%H:%M:%S"
                              timeZone:nil locale:nil]];
  [fileSizeMeasureField setStringValue: 
    [mainBundle localizedStringForKey: [treeHistory fileSizeMeasure] value: nil
                  table: @"Names"]];
  [treeSizeField setStringValue: 
    [FileItem stringForFileItemSize: [visibleTree itemSize]]];
  unsigned long long  freeSpace = [treeHistory freeSpace];
  [freeSpaceField setStringValue: [FileItem stringForFileItemSize: freeSpace]];
  [super windowDidLoad];
  
  NSAssert(invisiblePathName == nil, @"invisiblePathName unexpectedly set.");
  invisiblePathName = [[visibleTree stringForFileItemPath] retain];

  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(updateButtonState:)
        name:@"selectedItemChanged" object:itemPathModel];
  [nc addObserver:self selector:@selector(updateButtonState:)
        name:@"visiblePathLockingChanged" object:itemPathModel];
  [nc addObserver:self selector:@selector(visibleTreeChanged:)
        name:@"visibleTreeChanged" object:itemPathModel];

  [self visibleTreeChanged: nil];

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
  [itemPathModel moveVisibleTreeUp];
  
  // Automatically lock path as well.
  [itemPathModel setVisiblePathLocking:YES];
}

- (IBAction) downAction:(id)sender {
  [itemPathModel moveVisibleTreeDown];
}

- (IBAction) openFileInFinder:(id)sender {
  NSString  *filePath = 
    [[itemPathModel selectedFileItem] stringForFileItemPath];
  NSLog(@"root=%@ file=%@", invisiblePathName, filePath);

  [[NSWorkspace sharedWorkspace] 
    selectFile: filePath inFileViewerRootedAtPath: invisiblePathName];
}


- (IBAction) maskCheckBoxChanged:(id)sender {
  [self updateMask];
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


- (IBAction) colorMappingChanged: (id) sender {
  NSString  *localizedName = [colorMappingPopUp titleOfSelectedItem];
  NSString  *name = 
    [localizedColorMappingNamesReverseLookup objectForKey: localizedName];
  FileItemHashing  *mapping = [colorMappings fileItemHashingForKey: name];

  if (mapping != nil) {
    [mainView setTreeDrawerSettings: 
      [[mainView treeDrawerSettings] copyWithColorMapping: mapping]];
  }
}

- (IBAction) colorPaletteChanged: (id) sender {
  NSString  *localizedName = [colorPalettePopUp titleOfSelectedItem];
  NSString  *name = 
    [localizedColorPaletteNamesReverseLookup objectForKey: localizedName];
  NSColorList  *palette = [colorPalettes colorListForKey: name];

  if (palette != nil) {  
    [mainView setTreeDrawerSettings: 
      [[mainView treeDrawerSettings] copyWithColorPalette: palette]];
  }
}

- (IBAction) showEntireVolumeCheckBoxChanged: (id) sender {
  [mainView setShowEntireVolume: 
    [showEntireVolumeCheckBox state]==NSOnState ? YES : NO];
}


+ (NSDictionary*) addLocalisedNamesToPopUp: (NSPopUpButton *)popUp
                    names: (NSArray *)names
                    selectName: (NSString *)selectName
                    table: (NSString *)tableName {
                   
  NSBundle  *mainBundle = [NSBundle mainBundle];
  
  NSMutableDictionary  *reverseLookup = 
    [NSMutableDictionary dictionaryWithCapacity: [names count]];

  NSEnumerator  *enumerator = [names objectEnumerator];
  NSString  *name;
  NSString  *localizedSelect = nil;
  
  while (name = [enumerator nextObject]) {
    NSString  *localizedName = 
      [mainBundle localizedStringForKey: name value: nil table: tableName];

    [reverseLookup setObject: name forKey: localizedName];
    if ([name isEqualToString: selectName]) {
      localizedSelect = localizedName;
    }
  }
  
  [popUp addItemsWithTitles:
     [[reverseLookup allKeys] 
         sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)]];
  
  if (localizedSelect != nil) {
    [popUp selectItemWithTitle: localizedSelect];
  }
  
  return reverseLookup;
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

- (void) visibleTreeChanged:(NSNotification*)notification {
  FileItem  *visibleTree = [itemPathModel visibleTree];
  
  [invisiblePathName release];
  invisiblePathName = [[visibleTree stringForFileItemPath] retain];

  [visibleFolderPathTextView setString: invisiblePathName];

  ITEM_SIZE  itemSize = [visibleTree itemSize];
  [visibleFolderExactSizeField setStringValue:
     [FileItem exactStringForFileItemSize: itemSize]];
  [visibleFolderSizeField setStringValue:
     [NSString stringWithFormat: @"(%@)", 
                 [FileItem stringForFileItemSize: itemSize]]];

  [self updateButtonState:notification];
}


- (void) updateButtonState:(NSNotification*)notification {
  [upButton setEnabled: [itemPathModel canMoveVisibleTreeUp]];
  [downButton setEnabled: [itemPathModel isVisiblePathLocked] &&
                          [itemPathModel canMoveVisibleTreeDown] &&
                          ( [itemPathModel selectedFileItem] !=
                            [itemPathModel visibleTree] )] ;
  [openButton setEnabled: [itemPathModel isVisiblePathLocked] ];
  
  NSString  *selectedFileTitle = 
    NSLocalizedString( @"Selected file:", "Label in Focus panel" );

  FileItem  *selectedItem = [mainView selectedItem];

  if ( selectedItem != nil ) {
    ITEM_SIZE  itemSize = [selectedItem itemSize];
    NSString  *itemSizeString = [FileItem stringForFileItemSize: itemSize];

    [itemSizeField setStringValue: itemSizeString];

    NSString  *itemPath;
    NSString  *relativeItemPath;

    if ([selectedItem isSpecial]) {
      relativeItemPath = [selectedItem name];
      itemPath = [rootPathName stringByAppendingFormat: @" [%@]", 
                                 relativeItemPath];
    }
    else {
      itemPath = [selectedItem stringForFileItemPath];
      
      NSAssert([itemPath hasPrefix: rootPathName], @"Invalid path prefix.");
      relativeItemPath = [itemPath substringFromIndex: [rootPathName length]];
      if ([relativeItemPath isAbsolutePath]) {
        // Strip leading slash.
        relativeItemPath = [relativeItemPath substringFromIndex: 1];
      }
      
      if ([itemPath hasPrefix: invisiblePathName]) {
        // Create attributed string for the path of the selected item. The
        // root of the scanned tree is excluded from the path, and the part 
        // that is inside the visible tree is marked using different
        // attributes.
    
        int  visLen = [itemPath length] - [invisiblePathName length] - 1;
        NSMutableAttributedString  *attributedPath = 
          [[[NSMutableAttributedString alloc] 
               initWithString: relativeItemPath] autorelease];
        if (visLen > 0) {
          [attributedPath addAttribute: NSForegroundColorAttributeName
                            value: [NSColor darkGrayColor] 
                            range: NSMakeRange([relativeItemPath length]-visLen, 
                                               visLen) ];
        }

        relativeItemPath = (NSString *)attributedPath;
      }
    }
    [itemPathField setStringValue: relativeItemPath];

    [selectedItemTitleField setStringValue:
      ([selectedItem isPlainFile] ?
         selectedFileTitle :
         NSLocalizedString( @"Selected folder:", "Label in Focus panel" ) )];
    [selectedItemPathTextView setString: itemPath];
    [selectedItemExactSizeField setStringValue: 
       [FileItem exactStringForFileItemSize: itemSize]];
    [selectedItemSizeField setStringValue: 
       [NSString stringWithFormat: @"(%@)", itemSizeString]];
  }
  else {
    // There's no selected item
    [itemSizeField setStringValue: @""];
    [itemPathField setStringValue: @""];
    [selectedItemTitleField setStringValue: selectedFileTitle];
    [selectedItemPathTextView setString: @""];
    [selectedItemExactSizeField setStringValue: @""];
    [selectedItemSizeField setStringValue: @""];
  }
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
  
  [self updateMask];
}
  
- (void) updateMask {
  NSObject <FileItemTest>  *newMask = 
    [maskCheckBox state]==NSOnState ? fileItemMask : nil;

  [mainView setTreeDrawerSettings: 
    [[mainView treeDrawerSettings] copyWithFileItemMask: newMask]];
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
