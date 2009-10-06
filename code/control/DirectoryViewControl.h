#import <Cocoa/Cocoa.h>


extern NSString  *DeleteNothing;
extern NSString  *OnlyDeleteFiles;
extern NSString  *DeleteFilesAndFolders;


@class DirectoryItem;
@class DirectoryView;
@class ItemPathModel;
@class ItemPathModelView;
@class FileItemMappingCollection;
@class ColorListCollection;
@class EditFilterWindowControl;
@class ColorLegendTableViewControl;
@class DirectoryViewControlSettings;
@class TreeContext;
@class AnnotatedTreeContext;
@class ItemInFocusControls;
@class FileItemFilter;

@interface DirectoryViewControl : NSWindowController {

  // Main window
  IBOutlet NSTextField  *itemPathField;
  IBOutlet NSTextField  *itemSizeField;
  IBOutlet DirectoryView  *mainView;
  
  IBOutlet NSDrawer  *drawer;
  
  // "Display" drawer panel
  IBOutlet NSPopUpButton  *colorMappingPopUp;
  IBOutlet NSPopUpButton  *colorPalettePopUp;
  IBOutlet NSTableView  *colorLegendTable;
  IBOutlet NSButton  *maskCheckBox;
  IBOutlet NSButton  *showEntireVolumeCheckBox;
  IBOutlet NSButton  *showPackageContentsCheckBox;

  // "Info" drawer panel
  IBOutlet NSImageView  *volumeIconView;
  IBOutlet NSTextField  *volumeNameField;
  IBOutlet NSTextView  *scanPathTextView;
  IBOutlet NSTextField  *filterNameField;
  IBOutlet NSTextView  *commentsTextView;
  IBOutlet NSTextField  *scanTimeField;
  IBOutlet NSTextField  *fileSizeMeasureField;
  IBOutlet NSTextField  *volumeSizeField;
  IBOutlet NSTextField  *miscUsedSpaceField;
  IBOutlet NSTextField  *treeSizeField;
  IBOutlet NSTextField  *freeSpaceField;
  IBOutlet NSTextField  *freedSpaceField;
  IBOutlet NSTextField  *numScannedFilesField;
  IBOutlet NSTextField  *numDeletedFilesField;
  
  // "Focus" drawer panel
  IBOutlet NSTextField  *visibleFolderTitleField;
  IBOutlet NSTextView  *visibleFolderPathTextView;
  IBOutlet NSTextField  *visibleFolderExactSizeField;
  IBOutlet NSTextField  *visibleFolderSizeField;

  IBOutlet NSTextField  *selectedItemTitleField;
  IBOutlet NSTextView  *selectedItemPathTextView;
  IBOutlet NSTextField  *selectedItemExactSizeField;
  IBOutlet NSTextField  *selectedItemSizeField;

  IBOutlet NSTextField  *selectedItemTypeIdentifierField;
  ItemInFocusControls  *visibleFolderFocusControls;
  ItemInFocusControls  *selectedItemFocusControls;

  ItemPathModelView  *pathModelView;
  TreeContext  *treeContext;

  // The "initialSettings" and "initialComments" fields are only used between
  // initialization and subsequent creation of the window. The are subsequently
  // owned and managed by various GUI components.
  DirectoryViewControlSettings  *initialSettings;
  NSString  *initialComments;

  FileItemFilter  *fileItemMask;
  
  BOOL  canDeleteFiles;
  BOOL  canDeleteFolders;
  BOOL  confirmFileDeletion;
  BOOL  confirmFolderDeletion;

  FileItemMappingCollection  *colorMappings;
  ColorListCollection  *colorPalettes;
  ColorLegendTableViewControl  *colorLegendControl;
  
  EditFilterWindowControl  *editMaskFilterWindowControl;
  
  // The (absolute) path of the scan tree.
  NSString  *scanPathName;
  
  // The part of the (absolute) path that is outside the visible tree.
  NSString  *invisiblePathName;
  
  // The size of the view when it is not zoomed.
  NSSize  unzoomedViewSize;
}

- (IBAction) openFile: (id) sender;
- (IBAction) revealFileInFinder: (id) sender;
- (IBAction) deleteFile: (id) sender;
- (IBAction) toggleDrawer: (id) sender;

- (IBAction) maskCheckBoxChanged: (id) sender;
- (IBAction) editMask: (id) sender;

- (IBAction) colorMappingChanged: (id) sender;
- (IBAction) colorPaletteChanged: (id) sender;
- (IBAction) showEntireVolumeCheckBoxChanged: (id) sender;
- (IBAction) showPackageContentsCheckBoxChanged: (id) sender;

- (id) initWithAnnotatedTreeContext: (AnnotatedTreeContext *)treeContext;
- (id) initWithAnnotatedTreeContext: (AnnotatedTreeContext *)treeContext
         pathModel: (ItemPathModel *)itemPathModel
         settings: (DirectoryViewControlSettings *)settings;

- (FileItemFilter *) fileItemMask;

- (ItemPathModelView *) pathModelView;

- (DirectoryView*) directoryView;

// Returns the current settings of the view.
- (DirectoryViewControlSettings*) directoryViewControlSettings;

- (TreeContext*) treeContext;
- (AnnotatedTreeContext *) annotatedTreeContext;

- (BOOL) canOpenSelectedFile;
- (BOOL) canRevealSelectedFile;
- (BOOL) canDeleteSelectedFile;

+ (NSArray *) fileDeletionTargetNames;

@end
