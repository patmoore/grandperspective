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
@class ItemInFocusControls;
@protocol FileItemTest;

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
  IBOutlet NSTextView  *filterDescriptionTextView;
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
  DirectoryViewControlSettings  *initialSettings;
  TreeContext  *treeContext;

  NSObject <FileItemTest>  *fileItemMask;
  
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

- (id) initWithTreeContext: (TreeContext *)treeContext;
- (id) initWithTreeContext: (TreeContext *)treeContext
         pathModel: (ItemPathModel *)itemPathModel
         settings: (DirectoryViewControlSettings *)settings;

- (NSObject <FileItemTest> *) fileItemMask;

- (ItemPathModelView *) pathModelView;

- (DirectoryView*) directoryView;

// Returns the current settings of the view.
- (DirectoryViewControlSettings*) directoryViewControlSettings;

- (TreeContext*) treeContext;

- (BOOL) canOpenSelectedFile;
- (BOOL) canRevealSelectedFile;
- (BOOL) canDeleteSelectedFile;

+ (NSArray *) fileDeletionTargetNames;

@end
