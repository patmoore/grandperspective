#import "DirectoryViewControl.h"

#import "PlainFileItem.h"
#import "DirectoryItem.h"
#import "DirectoryView.h"
#import "ItemPathModel.h"
#import "ItemPathModelView.h"
#import "FileItemMappingScheme.h"
#import "FileItemMappingCollection.h"
#import "ColorListCollection.h"
#import "DirectoryViewControlSettings.h"
#import "NamedFilter.h"
#import "Filter.h"
#import "FilterRepository.h"
#import "FilterTestRepository.h"
#import "FilterPopUpControl.h"
#import "TreeContext.h"
#import "AnnotatedTreeContext.h"

#import "ColorLegendTableViewControl.h"
#import "PreferencesPanelControl.h"
#import "MainMenuControl.h"

#import "TreeDrawerSettings.h"
#import "ControlConstants.h"
#import "UniformType.h"

#import "UniqueTagsTransformer.h"


NSString  *DeleteNothing = @"delete nothing";
NSString  *OnlyDeleteFiles = @"only delete files";
NSString  *DeleteFilesAndFolders = @"delete files and folders";


#define NOTE_IT_MAY_NOT_EXIST_ANYMORE \
  NSLocalizedString( \
    @"A possible reason is that it does not exist anymore.", \
    @"Alert message (Note: 'it' can refer to a file or a folder)")


@interface DirectoryViewControl (PrivateMethods)

- (BOOL) canOpenSelectedFile;
- (BOOL) canRevealSelectedFile;
- (BOOL) canDeleteSelectedFile;
- (BOOL) canRescanSelectedFile;

- (void) informativeAlertDidEnd:(NSAlert *)alert 
           returnCode:(int) returnCode contextInfo:(void *)contextInfo;

- (void) confirmDeleteSelectedFileAlertDidEnd:(NSAlert *)alert 
           returnCode:(int) returnCode contextInfo:(void *)contextInfo;
- (void) deleteSelectedFile;
- (void) fileItemDeleted:(NSNotification *)notification;

- (void) selectedItemChanged:(NSNotification *)notification;
- (void) visibleTreeChanged:(NSNotification *)notification;
- (void) visiblePathLockingChanged:(NSNotification *)notification;

- (void) maskRemoved:(NSNotification *)notification;
- (void) maskUpdated:(NSNotification *)notification;

- (NSString *)updateSelectionInStatusbar;
- (void) updateSelectionInFocusPanel:(NSString *)itemSizeString;
- (void) validateControls;

- (void) updateMask;

- (void) updateFileDeletionSupport;

@end


/* Manages a group of related controls in the Focus panel.
 */
@interface ItemInFocusControls : NSObject {
  NSTextView  *pathTextView;
  NSTextField  *titleField;
  NSTextField  *exactSizeField;
  NSTextField  *sizeField;
}

- (id) initWithPathTextView:(NSTextView *)textView 
         titleField:(NSTextField *)titleField
         exactSizeField:(NSTextField *)exactSizeField
         sizeField:(NSTextField *)sizeField;


/* Clears the controls.
 */
- (void) clear;

/* Show the details of the given item.
 */
- (void) showFileItem:(FileItem *)item;

/* Show the details of the given item. The provided "pathString" and 
 * "sizeString" provided will be used (if -showFileItem: is invoked instead, 
 * these will be constructed before invoking this method). Invoking this method
 * directly is useful in cases where these have been constructed already (to 
 * avoid having to do so twice).
 */
- (void) showFileItem:(FileItem *)item itemPath:(NSString *)pathString
           sizeString:(NSString *)sizeString;

/* Abstract method. Override to return title for the given item.
 */
- (NSString *)titleForFileItem:(FileItem *)item;

@end


/* Manages the "Item in view" controls in the Focus panel.
 */
@interface  FolderInViewFocusControls : ItemInFocusControls {
}
@end


/* Manages the "Selected item" controls in the Focus panel.
 */
@interface  SelectedItemFocusControls : ItemInFocusControls {
}
@end


@implementation DirectoryViewControl

- (id) initWithAnnotatedTreeContext:(AnnotatedTreeContext *)annTreeContext {
  ItemPathModel  *pathModel = 
    [[[ItemPathModel alloc] initWithTreeContext: 
                              [annTreeContext treeContext]] autorelease];

  // Default settings
  DirectoryViewControlSettings  *defaultSettings =
    [[[DirectoryViewControlSettings alloc] init] autorelease];

  return [self initWithAnnotatedTreeContext: annTreeContext
                 pathModel: pathModel 
                 settings: defaultSettings];
}


// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) initWithAnnotatedTreeContext:(AnnotatedTreeContext *)annTreeContext
         pathModel:(ItemPathModel *)pathModel
         settings:(DirectoryViewControlSettings *)settings {
  return [self initWithAnnotatedTreeContext: annTreeContext
                 pathModel: pathModel 
                 settings: settings
                 filterRepository: [FilterRepository defaultInstance]];
}
         
- (id) initWithAnnotatedTreeContext:(AnnotatedTreeContext *)annTreeContext
         pathModel:(ItemPathModel *)pathModel
         settings:(DirectoryViewControlSettings *)settings
         filterRepository:(FilterRepository *)filterRepositoryVal {        
  if (self = [super initWithWindowNibName: @"DirectoryViewWindow"
                      owner: self]) {
    treeContext = [[annTreeContext treeContext] retain];
    NSAssert([pathModel volumeTree] == [treeContext volumeTree], 
               @"Tree mismatch");
    initialComments = [[annTreeContext comments] retain];
    
    pathModelView = [[ItemPathModelView alloc] initWithPathModel: pathModel];
    initialSettings = [settings retain];
    
    filterRepository = [filterRepositoryVal retain];

    scanPathName = [[[treeContext scanTree] path] retain];
    
    invisiblePathName = nil;
       
    colorMappings = 
      [[FileItemMappingCollection defaultFileItemMappingCollection] retain];
    colorPalettes = [[ColorListCollection defaultColorListCollection] retain];
  }

  return self;
}


- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults removeObserver: self forKeyPath: FileDeletionTargetsKey];
  [userDefaults removeObserver: self forKeyPath: ConfirmFileDeletionKey];
  
  [visibleFolderFocusControls release];
  [selectedItemFocusControls release];
  
  [treeContext release];
  [pathModelView release];
  [initialSettings release];
  [initialComments release];
  
  [colorMappings release];
  [colorPalettes release];
  [colorLegendControl release];
  [maskPopUpControl release];

  [scanPathName release];
  [invisiblePathName release];
  
  [super dealloc];
}


- (Filter *)mask {
  if ([maskCheckBox state]==NSOnState) {
    NSString  *maskName = [maskPopUpControl selectedFilterName];
    return [[filterRepository filtersByName] objectForKey: maskName];
  }
  else {
    return nil;
  }
}

- (NamedFilter *)namedMask {
  Filter  *mask = [self mask];
  if (mask == nil) {
    return nil;
  }
  else {
    return [NamedFilter namedFilter: mask 
                          name: [maskPopUpControl selectedFilterName]];
  }
}

- (ItemPathModelView *)pathModelView {
  return pathModelView;
}

- (DirectoryView *)directoryView {
  return mainView;
}

- (DirectoryViewControlSettings *)directoryViewControlSettings {
  UniqueTagsTransformer  *tagMaker = 
    [UniqueTagsTransformer defaultUniqueTagsTransformer];
  NSString  *colorMappingKey = 
    [tagMaker nameForTag: [[colorMappingPopUp selectedItem] tag]];
  NSString  *colorPaletteKey = 
    [tagMaker nameForTag: [[colorPalettePopUp selectedItem] tag]];
  NSString  *maskName = [tagMaker nameForTag: [[maskPopUp selectedItem] tag]];

  return 
    [[[DirectoryViewControlSettings alloc]
         initWithColorMappingKey: colorMappingKey
           colorPaletteKey: colorPaletteKey
           maskName: maskName
           maskEnabled: [maskCheckBox state]==NSOnState
           showEntireVolume: [showEntireVolumeCheckBox state]==NSOnState
           showPackageContents: [showPackageContentsCheckBox state]==NSOnState
           unzoomedViewSize: unzoomedViewSize]
         autorelease];
}

- (TreeContext *)treeContext {
  return treeContext;
}

- (AnnotatedTreeContext *)annotatedTreeContext {
  return [AnnotatedTreeContext annotatedTreeContext: treeContext 
                                 comments: [commentsTextView string]];
}

- (void) windowDidLoad {
  [mainView postInitWithPathModelView: pathModelView];
  
  [self updateFileDeletionSupport];

  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  NSBundle  *mainBundle = [NSBundle mainBundle];
  
  //----------------------------------------------------------------
  // Configure the "Display" panel
  
  UniqueTagsTransformer  *tagMaker = 
    [UniqueTagsTransformer defaultUniqueTagsTransformer];
  
  [colorMappingPopUp removeAllItems]; 
  [tagMaker addLocalisedNames: [colorMappings allKeys]
              toPopUp: colorMappingPopUp
              select: [initialSettings colorMappingKey]
              table: @"Names"];
  [self colorMappingChanged: nil];
  
  [colorPalettePopUp removeAllItems];
  [tagMaker addLocalisedNames: [colorPalettes allKeys]
              toPopUp: colorPalettePopUp
              select: [initialSettings colorPaletteKey] 
              table: @"Names"];
  [self colorPaletteChanged: nil];
  
  maskPopUpControl = 
    [[FilterPopUpControl alloc] initWithPopUpButton: maskPopUp
                                  filterRepository: filterRepository];
  NSNotificationCenter  *nc = [maskPopUpControl notificationCenter];
  [nc addObserver: self selector: @selector(maskRemoved:) 
          name: SelectedFilterRemoved object: maskPopUpControl];
  [nc addObserver: self selector: @selector(maskUpdated:) 
          name: SelectedFilterUpdated object: maskPopUpControl];  
  [maskCheckBox setState: ( [initialSettings fileItemMaskEnabled]
                              ? NSOnState : NSOffState ) ];
  [self updateMask];
  
  // NSTableView apparently does not retain its data source, so keeping a
  // reference here so that it can be released.
  colorLegendControl = 
    [[ColorLegendTableViewControl alloc] initWithDirectoryView: mainView 
                                           tableView: colorLegendTable];
    
  [showEntireVolumeCheckBox setState: 
     ( [initialSettings showEntireVolume] ? NSOnState : NSOffState ) ]; 
  [showPackageContentsCheckBox setState: 
     ( [initialSettings showPackageContents] ? NSOnState : NSOffState ) ];
  
  //---------------------------------------------------------------- 
  // Configure the "Info" panel

  FileItem  *volumeTree = [pathModelView volumeTree];
  FileItem  *scanTree = [pathModelView scanTree];
  FileItem  *visibleTree = [pathModelView visibleTree];

  NSString  *volumeName = [volumeTree name];
  NSImage  *volumeIcon = 
    [[NSWorkspace sharedWorkspace] iconForFile: volumeName];
  [volumeIconView setImage: volumeIcon];

  [volumeNameField setStringValue: 
    [[NSFileManager defaultManager] displayNameAtPath: volumeName]];

  [scanPathTextView setString: [scanTree name]];
  [scanPathTextView setDrawsBackground: NO];
  [[scanPathTextView enclosingScrollView] setDrawsBackground: NO];

  FilterSet  *filterSet = [treeContext filterSet];
  [filterNameField setStringValue: 
    ( ([filterSet fileItemTest] != nil)
      ? [filterSet description]
      : NSLocalizedString( @"None", 
                           @"The filter name when there is no filter." ) ) ];

  [commentsTextView setString: initialComments];
  
  [scanTimeField setStringValue: [treeContext stringForScanTime]];
  [fileSizeMeasureField setStringValue: 
    [mainBundle localizedStringForKey: [treeContext fileSizeMeasure] value: nil
                  table: @"Names"]];

  unsigned long long  scanTreeSize = [scanTree itemSize];
  unsigned long long  freeSpace = [treeContext freeSpace];
  unsigned long long  volumeSize = [volumeTree itemSize];
  unsigned long long  miscUsedSpace = volumeSize - freeSpace - scanTreeSize;

  [volumeSizeField setStringValue: 
       [FileItem stringForFileItemSize: volumeSize]]; 
  [treeSizeField setStringValue: 
       [FileItem stringForFileItemSize: scanTreeSize]];
  [miscUsedSpaceField setStringValue: 
       [FileItem stringForFileItemSize: miscUsedSpace]];
  [freeSpaceField setStringValue: 
       [FileItem stringForFileItemSize: freeSpace]];
  [freedSpaceField setStringValue: 
       [FileItem stringForFileItemSize: [treeContext freedSpace]]];
  [numScannedFilesField setStringValue: 
       [NSString stringWithFormat: @"%qu", [scanTree numFiles]]];
  [numDeletedFilesField setStringValue:
       [NSString stringWithFormat: @"%qu", [treeContext freedFiles]]];

                   
  //---------------------------------------------------------------- 
  // Configure the "Focus" panel
  
  visibleFolderFocusControls = 
    [[FolderInViewFocusControls alloc]
        initWithPathTextView: visibleFolderPathTextView 
          titleField: visibleFolderTitleField
          exactSizeField: visibleFolderExactSizeField
          sizeField: visibleFolderSizeField];

  selectedItemFocusControls = 
    [[SelectedItemFocusControls alloc]
        initWithPathTextView: selectedItemPathTextView 
          titleField: selectedItemTitleField
          exactSizeField: selectedItemExactSizeField
          sizeField: selectedItemSizeField];


  //---------------------------------------------------------------- 
  // Miscellaneous initialisation

  [super windowDidLoad];
  
  NSAssert(invisiblePathName == nil, @"invisiblePathName unexpectedly set.");
  invisiblePathName = [[visibleTree path] retain];

  [self showEntireVolumeCheckBoxChanged: nil];
  [self showPackageContentsCheckBoxChanged: nil];

  nc = [NSNotificationCenter defaultCenter];

  [nc addObserver:self selector: @selector(selectedItemChanged:)
        name: SelectedItemChangedEvent object: pathModelView];
  [nc addObserver:self selector: @selector(visibleTreeChanged:)
        name: VisibleTreeChangedEvent object: pathModelView];
  [nc addObserver:self selector: @selector(visiblePathLockingChanged:)
        name: VisiblePathLockingChangedEvent object: [pathModelView pathModel]];
        
  [userDefaults addObserver: self forKeyPath: FileDeletionTargetsKey
                  options: 0 context: nil];
  [userDefaults addObserver: self forKeyPath: ConfirmFileDeletionKey
                  options: 0 context: nil];

  [nc addObserver:self selector: @selector(fileItemDeleted:)
        name: FileItemDeletedEvent object: treeContext];

  [self visibleTreeChanged: nil];
  
  // Set the window's initial size
  unzoomedViewSize = [initialSettings unzoomedViewSize];
  NSRect  frame = [[self window] frame];
  frame.size = unzoomedViewSize;
  [[self window] setFrame: frame display: NO];
  
  [[self window] makeFirstResponder:mainView];
  [[self window] makeKeyAndOrderFront:self];
  
  [initialSettings release];
  initialSettings = nil;
  
  [initialComments release];
  initialComments = nil;
}


// Invoked because the controller is the delegate for the window.
- (void) windowDidBecomeMain:(NSNotification *)notification {
  // Change window's background color (which should only affect the statusbar)
  [[self window] setBackgroundColor: [NSColor lightGrayColor]]; 
}

- (void) windowDidResignMain:(NSNotification *)notification {
  float  h, s, b, a;
  
  [[[[self window] backgroundColor] 
        colorUsingColorSpaceName: NSDeviceRGBColorSpace]
          getHue: &h saturation: &s brightness: &b alpha: &a];
            
  NSColor  *inactiveBackgroundColor = 
    [NSColor colorWithDeviceHue: h saturation: s 
               brightness: 1 - 0.5 * (1-b) alpha: a];

  [[self window] setBackgroundColor: inactiveBackgroundColor]; 
}


// Invoked because the controller is the delegate for the window.
- (void) windowWillClose:(NSNotification *)notification {
  [self autorelease];
}

// Invoked because the controller is the delegate for the window.
- (void) windowDidResize:(NSNotification *)notification {
  if (! [[self window] isZoomed]) {
    // Keep track of the user-state size of the window, as this will be uses as
    // the initial size of derived views.
    unzoomedViewSize = [[self window] frame].size;
  }
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id) object 
           change:(NSDictionary *)change context:(void *)context {
  if (object == [NSUserDefaults standardUserDefaults]) {
    if ([keyPath isEqualToString: FileDeletionTargetsKey] ||
        [keyPath isEqualToString: ConfirmFileDeletionKey]) {
      [self updateFileDeletionSupport];
    }
  }
}


- (IBAction) openFile:(id) sender {
  FileItem  *file = [pathModelView selectedFileItem];
  NSString  *filePath = [file systemPath];

  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  NSString  *customApp = 
    [userDefaults stringForKey: CustomFileOpenApplication];
  NSWorkspace  *workspace = [NSWorkspace sharedWorkspace];

  if ([customApp length] > 0) {
    NSLog(@"Opening using customApp");
    if ( [workspace openFile: filePath withApplication: customApp] ) {
      return; // All went okay
    }
  }
  else {
    if ( [workspace openFile: filePath] ) {
      return; // All went okay
    }
  }
  
  NSAlert *alert = [[[NSAlert alloc] init] autorelease];

  NSString  *msgFmt = 
    ( [file isPackage]
      ? NSLocalizedString(@"Failed to open the package \"%@\"", 
                          @"Alert message")
      : ( [file isDirectory] 
          // Opening directories should not be enabled, but handle it anyway
          // here, just for robustness...
          ? NSLocalizedString(@"Failed to open the folder \"%@\"", 
                              @"Alert message")
          : NSLocalizedString(@"Failed to open the file \"%@\"", 
                              @"Alert message") ) );
  NSString  *msg = [NSString stringWithFormat: msgFmt, [file name]];
         
  [alert addButtonWithTitle: OK_BUTTON_TITLE];
  [alert setMessageText: msg];
  [alert setInformativeText: NOTE_IT_MAY_NOT_EXIST_ANYMORE];

  [alert beginSheetModalForWindow: [self window] modalDelegate: self
           didEndSelector: @selector(informativeAlertDidEnd: 
                                       returnCode:contextInfo:) 
           contextInfo: nil];
}


- (IBAction) revealFileInFinder:(id) sender {
  FileItem  *file = [pathModelView selectedFileItem];
  NSString  *filePath = [file systemPath];
  
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  NSString  *customApp = 
    [userDefaults stringForKey: CustomFileRevealApplication];
  NSWorkspace  *workspace = [NSWorkspace sharedWorkspace];

  if ([customApp length] > 0) {
    NSLog(@"Revealing using customApp %@.", customApp);
    if ( [workspace openFile: filePath withApplication: customApp] ) {
      return; // All went okay
    }
  }
  else { 
    // Work-around for bug/limitation of NSWorkSpace. It apparently cannot 
    // select files that are inside a package, unless the package is the root
    // path. So check if the selected file is inside a package. If so, use it
    // as a root path.
    DirectoryItem  *ancestor = [file parentDirectory];
    DirectoryItem  *package = nil;
 
    while (ancestor != nil) {
      if ( [ancestor isPackage] ) {
        if (package != nil) {
          // The package in which the selected item resides is inside a package
          // itself. Open this inner package instead (as opening the selected
          // file will not succeed).
          file = package;
        }
        package = ancestor;
      }
      ancestor = [ancestor parentDirectory];
    }
    
    // Note: This does not work properly when the system representation of the
    // invisiblePathName differs from its friendly representation, i.e. when
    // it contains slashes in any of its path components. So be it. This
    // happens rarely and would then only be a minor cosmetic flaw anyway.
    NSString  *rootPath = 
      (package != nil) ? [package systemPath] : invisiblePathName;

    if ( [[NSWorkspace sharedWorkspace] 
             selectFile: filePath 
             inFileViewerRootedAtPath: rootPath] ) {
      return; // All went okay
    }
  }
  
  NSAlert *alert = [[[NSAlert alloc] init] autorelease];

  NSString  *msgFmt = 
    ( [file isPackage]
      ? NSLocalizedString(@"Failed to reveal the package \"%@\"", 
                          @"Alert message")
      : ( [file isDirectory] 
          ? NSLocalizedString(@"Failed to reveal the folder \"%@\"", 
                              @"Alert message")
          : NSLocalizedString(@"Failed to reveal the file \"%@\"", 
                              @"Alert message") ) );
  NSString  *msg = [NSString stringWithFormat: msgFmt, [file name]];
         
  [alert addButtonWithTitle: OK_BUTTON_TITLE];
  [alert setMessageText: msg];
  [alert setInformativeText: NOTE_IT_MAY_NOT_EXIST_ANYMORE];

  [alert beginSheetModalForWindow: [self window] modalDelegate: self
           didEndSelector: @selector(informativeAlertDidEnd: 
                                       returnCode:contextInfo:) 
           contextInfo: nil];
}


- (IBAction) deleteFile:(id) sender {
  FileItem  *selectedFile = [pathModelView selectedFileItem];
  BOOL  isDir = [selectedFile isDirectory];
  BOOL  isPackage = [selectedFile isPackage];

  // Packages whose contents are hidden (i.e. who are not represented as
  // directories) are treated schizophrenically for deletion: For deciding if
  // a confirmation message needs to be shown, they are treated as directories.
  // However, for determining if they can be deleted they are treated as files.

  if ( ( !(isDir || isPackage) && !confirmFileDeletion) ||
       (  (isDir || isPackage) && !confirmFolderDeletion) ) {
    // Delete the file/folder immediately, without asking for confirmation.
    [self deleteSelectedFile];
    
    return;
  }

  NSAlert  *alert = [[[NSAlert alloc] init] autorelease];
  NSString  *mainMsg;
  NSString  *infoMsg;
  NSString  *hardLinkMsg;

  if (isDir) {
    mainMsg = NSLocalizedString( @"Do you want to delete the folder \"%@\"?", 
                                 @"Alert message" );
    infoMsg = NSLocalizedString( 
      @"The selected folder, with all its contents, will be moved to Trash. Beware, any files in the folder that are not shown in the view will also be deleted.", 
      @"Alert informative text" );
    hardLinkMsg = NSLocalizedString(
      @"Note: The folder is hard-linked. It will take up space until all links to it are deleted.",
      @"Alert additional informative text" );
  }
  else if (isPackage) {
    mainMsg = NSLocalizedString( @"Do you want to delete the package \"%@\"?", 
                                 @"Alert message" );
    infoMsg = NSLocalizedString( 
                @"The selected package will be moved to Trash.", 
                @"Alert informative text" );
    hardLinkMsg = NSLocalizedString( 
      @"Note: The package is hard-linked. It will take up space until all links to it are deleted.",
      @"Alert additional informative text" );
  }
  else {
    mainMsg = NSLocalizedString( @"Do you want to delete the file \"%@\"?", 
                                 @"Alert message" );
    infoMsg = NSLocalizedString( @"The selected file will be moved to Trash.", 
                                 @"Alert informative text" );
    hardLinkMsg = NSLocalizedString( 
      @"Note: The file is hard-linked. It will take up space until all links to it are deleted.",
      @"Alert additional informative text" );
  }
  
  if ( [selectedFile isHardLinked] ) {
    infoMsg = [NSString stringWithFormat: @"%@\n\n%@", infoMsg, hardLinkMsg];
  }

  NSBundle  *mainBundle = [NSBundle mainBundle];
  
  [alert addButtonWithTitle: DELETE_BUTTON_TITLE];
  [alert addButtonWithTitle: CANCEL_BUTTON_TITLE];
  [alert setMessageText: [NSString stringWithFormat: mainMsg, 
                                     [[selectedFile name] lastPathComponent]]];
                                     // Note: using lastPathComponent, as the
                                     // scan tree item's name is relative to 
                                     // the volume root.
  [alert setInformativeText: infoMsg];

  [alert beginSheetModalForWindow: [self window] modalDelegate: self
           didEndSelector: @selector(confirmDeleteSelectedFileAlertDidEnd: 
                                       returnCode:contextInfo:) 
           contextInfo: nil];
}


- (IBAction) rescanFile:(id) sender {
  [[MainMenuControl singletonInstance] rescanSelectedFile: sender];
}


- (IBAction) toggleDrawer:(id) sender {
  [drawer toggle: sender];
}


- (IBAction) colorMappingChanged:(id) sender {
  UniqueTagsTransformer  *tagMaker = 
    [UniqueTagsTransformer defaultUniqueTagsTransformer];

  NSString  *name = 
    [tagMaker nameForTag: [[colorMappingPopUp selectedItem] tag]];
  NSObject <FileItemMappingScheme>  *mapping = 
    [colorMappings fileItemMappingSchemeForKey: name];

  if (mapping != nil) {
    NSObject <FileItemMapping>  *mapper = [mapping fileItemMapping];
  
    [mainView setTreeDrawerSettings: 
      [[mainView treeDrawerSettings] copyWithColorMapper: mapper]];
  }
}

- (IBAction) colorPaletteChanged:(id) sender {
  UniqueTagsTransformer  *tagMaker = 
    [UniqueTagsTransformer defaultUniqueTagsTransformer];
  NSString  *name = 
    [tagMaker nameForTag: [[colorPalettePopUp selectedItem] tag]];
  NSColorList  *palette = [colorPalettes colorListForKey: name];

  if (palette != nil) { 
    [mainView setTreeDrawerSettings: 
      [[mainView treeDrawerSettings] copyWithColorPalette: palette]];
  }
}

- (IBAction) maskChanged:(id) sender {
  // Automatically enable the mask
  [maskCheckBox setState: NSOnState];
    
  [self updateMask];
}

- (IBAction) maskCheckBoxChanged:(id) sender {
  [self updateMask];
}


- (IBAction) showEntireVolumeCheckBoxChanged:(id) sender {
  [mainView setShowEntireVolume: [showEntireVolumeCheckBox state]==NSOnState];
}

- (IBAction) showPackageContentsCheckBoxChanged:(id) sender {
  BOOL  showPackageContents = [showPackageContentsCheckBox state]==NSOnState;
  
  [mainView setTreeDrawerSettings: 
    [[mainView treeDrawerSettings] copyWithShowPackageContents: 
       showPackageContents]];
  [[mainView pathModelView] setShowPackageContents: showPackageContents];

  // If the selected item is a package, its info will have changed.
  [self selectedItemChanged: nil];
}


- (BOOL) validateAction:(SEL) action {
  if ( action == @selector(openFile:) ) {
    return [self canOpenSelectedFile];
  }
  else if ( action == @selector(revealFileInFinder:) ) {
    return [self canRevealSelectedFile];
  }
  else if ( action == @selector(deleteFile:) ) {
    return [self canDeleteSelectedFile];
  }
  else if ( action == @selector(rescanFile:) ) {
    return [self canRescanSelectedFile];
  }
  
  NSLog(@"Unsupported action");
  return NO;
}


- (BOOL) isSelectedFileLocked {
  return [[pathModelView pathModel] isVisiblePathLocked];
}


+ (NSArray *)fileDeletionTargetNames {
  static NSArray  *fileDeletionTargetNames = nil;
  
  if (fileDeletionTargetNames == nil) {
    fileDeletionTargetNames = 
      [[NSArray arrayWithObjects: DeleteNothing, OnlyDeleteFiles, 
                                    DeleteFilesAndFolders, nil] retain];
  }
  
  return fileDeletionTargetNames;
}

@end // @implementation DirectoryViewControl


@implementation DirectoryViewControl (PrivateMethods)

- (BOOL) canOpenSelectedFile {
  FileItem  *selectedFile = [pathModelView selectedFileItem];

  return
    ( // Can only open actual files
      [selectedFile isPhysical]
      
      // Can only open plain files and packages
      && ( ! [selectedFile isDirectory]
           || [selectedFile isPackage] )
    );
}

- (BOOL) canRevealSelectedFile {
  return [[pathModelView selectedFileItem] isPhysical];
}

- (BOOL) canDeleteSelectedFile {
  FileItem  *selectedFile = [pathModelView selectedFileItem];

  return 
    ( // Can only delete actual files.
      [selectedFile isPhysical] 

      // Can this type of item be deleted (according to the preferences)?
      && ( (canDeleteFiles && ![selectedFile isDirectory])
           || (canDeleteFolders && [selectedFile isDirectory]) ) 

      // Can only delete the entire scan tree when it is an actual folder 
      // within the volume. You cannot delete the root folder.
      && ! ( (selectedFile == [pathModelView scanTree])
             && [[[pathModelView scanTree] name] isEqualToString: @""])

      // Don't enable Click-through for deletion. The window needs to be 
      // active for the file deletion controls to be enabled.
      && [[self window] isKeyWindow]
    );
}

- (BOOL) canRescanSelectedFile {
  return [[pathModelView selectedFileItem] isPhysical];
}


- (void) informativeAlertDidEnd:(NSAlert *)alert 
           returnCode:(int) returnCode contextInfo:(void *)contextInfo {
  [[alert window] orderOut: self];
}


- (void) confirmDeleteSelectedFileAlertDidEnd:(NSAlert *)alert 
           returnCode:(int) returnCode contextInfo:(void *)contextInfo {
  // Let the alert disappear, so that it is gone before the file is being
  // deleted as this can trigger another alert (namely when it fails).
  [[alert window] orderOut: self];
  
  if (returnCode == NSAlertFirstButtonReturn) {
    // Delete confirmed.
    
    [self deleteSelectedFile];
  }
}

- (void) deleteSelectedFile {
  FileItem  *selectedFile = [pathModelView selectedFileItem];

  NSWorkspace  *workspace = [NSWorkspace sharedWorkspace];
  NSString  *sourceDir = [[selectedFile parentDirectory] path];
    // Note: Can always obtain the encompassing directory this way. The 
    // volume tree cannot be deleted so there is always a valid parent
    // directory.

  int  tag;
  if ([workspace performFileOperation: NSWorkspaceRecycleOperation
                   source: sourceDir
                   destination: @""
                   files: [NSArray arrayWithObject: [selectedFile name]]
                   tag: &tag]) {
    [treeContext deleteSelectedFileItem: pathModelView];
    
    return; // All went okay
  }

  NSAlert *alert = [[[NSAlert alloc] init] autorelease];

  NSString  *msgFmt = 
    ( [selectedFile isDirectory] 
      ? NSLocalizedString( @"Failed to delete the folder \"%@\"", 
                           @"Alert message")
      : NSLocalizedString( @"Failed to delete the file \"%@\"", 
                           @"Alert message") );
  NSString  *msg = [NSString stringWithFormat: msgFmt, [selectedFile name]];
  NSString  *info =
    NSLocalizedString(@"Possible reasons are that it does not exist anymore (it may have been moved, renamed, or deleted by other means) or that you lack the required permissions.", 
                      @"Alert message"); 
         
  [alert addButtonWithTitle: OK_BUTTON_TITLE];
  [alert setMessageText: msg];
  [alert setInformativeText: info];

  [alert beginSheetModalForWindow: [self window] modalDelegate: self
           didEndSelector: @selector(informativeAlertDidEnd: 
                                       returnCode:contextInfo:) 
           contextInfo: nil];
}

- (void) fileItemDeleted:(NSNotification *)notification {
  [freedSpaceField setStringValue: 
                   [FileItem stringForFileItemSize: [treeContext freedSpace]]];
  [numDeletedFilesField setStringValue:
                [NSString stringWithFormat: @"%qu", [treeContext freedFiles]]];
}


- (void) visibleTreeChanged:(NSNotification *)notification {
  FileItem  *visibleTree = [pathModelView visibleTree];
  
  [invisiblePathName release];
  invisiblePathName = [[visibleTree path] retain];

  [visibleFolderFocusControls showFileItem: visibleTree];

  [self validateControls];

  // Also update the status bar, as visible part is marked differently
  [self updateSelectionInStatusbar];
}

- (void) visiblePathLockingChanged:(NSNotification *)notification {
  [self validateControls];
}


- (void) selectedItemChanged:(NSNotification *)notification {
  NSString  *itemSizeString = [self updateSelectionInStatusbar];
  [self updateSelectionInFocusPanel: itemSizeString];
  
  if ([[pathModelView pathModel] isVisiblePathLocked]) {
    // Only when the visible path is locked can a change of selected item
    // affect the state of the controls.
    [self validateControls];
  }
}


- (void) maskRemoved:(NSNotification *)notification {
  [maskCheckBox setState: NSOffState];
    
  [self updateMask];
}

- (void) maskUpdated:(NSNotification *)notification {
  [self updateMask];
}


- (NSString *)updateSelectionInStatusbar {
  FileItem  *selectedItem = [pathModelView selectedFileItem];

  if ( selectedItem == nil ) {
    [itemSizeField setStringValue: @""];
    [itemPathField setStringValue: @""];
  
    return nil;
  }
  
  NSString  *itemSizeString = 
    [FileItem stringForFileItemSize: [selectedItem itemSize]];
  [itemSizeField setStringValue: itemSizeString];

  NSString  *itemPath;
  NSString  *relativeItemPath;

  if (! [selectedItem isPhysical]) {
    itemPath = 
      [[NSBundle mainBundle] localizedStringForKey: [selectedItem name] 
                               value: nil table: @"Names"];
    relativeItemPath = itemPath;
  }
  else {
    itemPath = [selectedItem path];
      
    NSAssert([itemPath hasPrefix: scanPathName], @"Invalid path prefix.");
    relativeItemPath = [itemPath substringFromIndex: [scanPathName length]];
    if ([relativeItemPath isAbsolutePath]) {
      // Strip leading slash.
      relativeItemPath = [relativeItemPath substringFromIndex: 1];
    }
      
    if ([itemPath hasPrefix: invisiblePathName]) {
      // Create attributed string for the path of the selected item. The
      // root of the scanned tree is excluded from the path, and the part 
      // that is inside the visible tree is marked using different
      // attributes. This indicates which folder is shown in the view.

      NSMutableAttributedString  *attributedPath = 
        [[[NSMutableAttributedString alloc] 
             initWithString: relativeItemPath] autorelease];

      int  visibleLen = [itemPath length] - [invisiblePathName length];
      if (visibleLen > 0) {
        // Let the path separator also be part of the invisible path.
        visibleLen--;
      }
        
      if ([relativeItemPath length] > visibleLen) {
        [attributedPath 
           addAttribute: NSForegroundColorAttributeName
             value: [NSColor darkGrayColor] 
             range: NSMakeRange(0, [relativeItemPath length] - visibleLen) ];
      }
        
      relativeItemPath = (NSString *)attributedPath;
    }
  }

  [itemPathField setStringValue: relativeItemPath];
  
  return itemSizeString;
}


// Note: For efficiency taking already constructed itemSizeString from 
// elsewhere, as opposed to constructing it again. 
- (void) updateSelectionInFocusPanel:(NSString *)itemSizeString {
  FileItem  *selectedItem = [pathModelView selectedFileItem];

  if ( selectedItem != nil ) {
    NSString  *itemPath;
    
    if (! [selectedItem isPhysical]) {
      itemPath = 
        [[NSBundle mainBundle] localizedStringForKey: [selectedItem name] 
                                 value: nil table: @"Names"];
    }
    else {
      itemPath = [selectedItem path];
    }

    [selectedItemFocusControls showFileItem: selectedItem itemPath: itemPath 
                                 sizeString: itemSizeString];
  }
  else {
    [selectedItemFocusControls clear]; 
  }

  // Update the file type fields in the Focus panel
  if ( selectedItem != nil &&
       [selectedItem isPhysical] &&
       ![selectedItem isDirectory] ) {
    UniformType  *type = [ ((PlainFileItem *)selectedItem) uniformType];
    
    [selectedItemTypeIdentifierField 
       setStringValue: [type uniformTypeIdentifier]];
    [selectedItemTypeIdentifierField
       setToolTip: ( [type description] != nil 
                     ? [type description] : [type uniformTypeIdentifier] )];
  }
  else {
    [selectedItemTypeIdentifierField setStringValue: @""];
    [selectedItemTypeIdentifierField setToolTip: nil]; 
  }
}


- (void) validateControls {
  // Note: Maybe not strictly necessary, as toolbar seems to frequently auto- 
  // update its visible items (unnecessarily often it seems). Nevertheless, 
  // it's good to do so explicitly, in response to relevant events.
  [[[self window] toolbar] validateVisibleItems];
}


- (void) updateMask {
  Filter  *mask = [self mask];
  
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  if ( mask != nil 
       && [userDefaults boolForKey: UpdateFiltersBeforeUse] ) {
    // Create a new filter (so that the file item test can be updated)
    mask = [Filter filterWithFilter: mask];
  }

  FileItemTest  *maskTest = [mask fileItemTest]; 
  if ( mask != nil && maskTest == nil ) {
    NSMutableArray  *unboundTests = [NSMutableArray arrayWithCapacity: 8];
    maskTest = [mask createFileItemTestFromRepository: 
                         [FilterTestRepository defaultInstance]
                       unboundTests: unboundTests];
    [MainMenuControl reportUnboundTests: unboundTests];
  }

  [mainView setTreeDrawerSettings: 
    [[mainView treeDrawerSettings] copyWithMaskTest: maskTest]];
}


- (void) updateFileDeletionSupport {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  
  NSString  *fileDeletionTargets = 
    [userDefaults stringForKey: FileDeletionTargetsKey];

  canDeleteFiles = 
    ([fileDeletionTargets isEqualToString: OnlyDeleteFiles] ||
     [fileDeletionTargets isEqualToString: DeleteFilesAndFolders]);
  canDeleteFolders =
     [fileDeletionTargets isEqualToString: DeleteFilesAndFolders];
  confirmFileDeletion = 
    [[userDefaults objectForKey: ConfirmFileDeletionKey] boolValue];
  confirmFolderDeletion = 
    [[userDefaults objectForKey: ConfirmFolderDeletionKey] boolValue];

  [self validateControls];
}

@end // @implementation DirectoryViewControl (PrivateMethods)


@implementation ItemInFocusControls

- (id) initWithPathTextView:(NSTextView *)pathTextViewVal
         titleField:(NSTextField *)titleFieldVal
         exactSizeField:(NSTextField *)exactSizeFieldVal
         sizeField:(NSTextField *)sizeFieldVal {
  if (self = [super init]) {
    pathTextView = [pathTextViewVal retain];
    titleField = [titleFieldVal retain];
    exactSizeField = [exactSizeFieldVal retain];
    sizeField = [sizeFieldVal retain];
  }

  return self;
}

- (void) dealloc {
  [titleField release];
  [pathTextView release];
  [exactSizeField release];
  [sizeField release];
  
  [super dealloc];
}


- (void) clear {
  [titleField setStringValue: [self titleForFileItem: nil]];
  [pathTextView setString: @""];
  [exactSizeField setStringValue: @""];
  [sizeField setStringValue: @""];
}


- (void) showFileItem:(FileItem *)item {
  NSString  *sizeString = [FileItem stringForFileItemSize: [item itemSize]];
  NSString  *itemPath = 
    ( [item isPhysical]
      ? [item path] 
      : [[NSBundle mainBundle] localizedStringForKey: [item name] 
                                 value: nil table: @"Names"] );
    
  [self showFileItem: item itemPath: itemPath sizeString: sizeString];
}


- (void) showFileItem:(FileItem *)item itemPath:(NSString *)pathString
           sizeString:(NSString *)sizeString {
  [titleField setStringValue: [self titleForFileItem: item]];
  
  [pathTextView setString: pathString];
  [exactSizeField setStringValue: 
     [FileItem exactStringForFileItemSize: [item itemSize]]];
  [sizeField setStringValue: [NSString stringWithFormat: @"(%@)", sizeString]];
       
  // Use the color of the size fields to show if the item is hard-linked.
  NSColor  *sizeFieldColor = ([item isHardLinked] 
                              ? [NSColor darkGrayColor]
                              : [titleField textColor]);
  [exactSizeField setTextColor: sizeFieldColor];
  [sizeField setTextColor: sizeFieldColor];
}


- (NSString *) titleForFileItem: (FileItem *)item {
  NSAssert(NO, @"Abstract method");
}

@end // @implementation ItemInFocusControls


@implementation FolderInViewFocusControls

- (NSString *)titleForFileItem:(FileItem *)item {
  if ( ! [item isPhysical] ) {
    return NSLocalizedString( @"Area in view:", "Label in Focus panel" );
  }
  else if ( [item isPackage] ) {
    return NSLocalizedString( @"Package in view:", "Label in Focus panel" );
  }
  else if ( [item isDirectory] ) {
    return NSLocalizedString( @"Folder in view:", "Label in Focus panel" );
  }
  else { // Default, also used when item == nil
    return NSLocalizedString( @"File in view:", "Label in Focus panel" );
  }
}

@end // @implementation FolderInViewFocusControls


@implementation SelectedItemFocusControls

- (NSString *)titleForFileItem:(FileItem *)item {
  if ( ! [item isPhysical] ) {
    return NSLocalizedString( @"Selected area:", "Label in Focus panel" );
  }
  else if ( [item isPackage] ) {
    return NSLocalizedString( @"Selected package:", "Label in Focus panel" );
  }
  else if ( [item isDirectory] ) {
    return NSLocalizedString( @"Selected folder:", "Label in Focus panel" );
  }
  else { // Default, also used when item == nil
    return NSLocalizedString( @"Selected file:", "Label in Focus panel" );
  }
}

@end // @implementation SelectedItemFocusControls
