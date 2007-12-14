#import <Cocoa/Cocoa.h>

@class DirectoryItem;
@class DirectoryView;
@class ItemPathModel;
@class FileItemHashingCollection;
@class ColorListCollection;
@class EditFilterWindowControl;
@class DirectoryViewControlSettings;
@class TreeContext;
@protocol FileItemTest;

@interface DirectoryViewControl : NSWindowController {

  // Main window
  IBOutlet NSTextField  *itemPathField;
  IBOutlet NSTextField  *itemSizeField;
  IBOutlet DirectoryView  *mainView;
  IBOutlet NSButton  *upButton;
  IBOutlet NSButton  *downButton;
  IBOutlet NSButton  *openButton;
  IBOutlet NSButton  *deleteButton;
  
  IBOutlet NSDrawer  *drawer;
  
  // "Display" drawer panel
  IBOutlet NSPopUpButton  *colorMappingPopUp;
  IBOutlet NSPopUpButton  *colorPalettePopUp;
  IBOutlet NSTextView  *maskDescriptionTextView;
  IBOutlet NSButton  *maskCheckBox;
  IBOutlet NSButton  *showEntireVolumeCheckBox;

  // "Info" drawer panel
  IBOutlet NSImageView  *volumeIconView;
  IBOutlet NSTextView  *volumeNameTextView;
  IBOutlet NSTextView  *scanPathTextView;
  IBOutlet NSTextField  *filterNameField;
  IBOutlet NSTextView  *filterDescriptionTextView;
  IBOutlet NSTextField  *scanTimeField;
  IBOutlet NSTextField  *fileSizeMeasureField;
  IBOutlet NSTextField  *volumeSizeField;
  IBOutlet NSTextField  *miscUsedSpaceField;
  IBOutlet NSTextField  *treeSizeField;
  IBOutlet NSTextField  *freeSpaceField;
  
  // "Focus" drawer panel
  IBOutlet NSTextView  *visibleFolderPathTextView;
  IBOutlet NSTextField  *visibleFolderExactSizeField;
  IBOutlet NSTextField  *visibleFolderSizeField;
  IBOutlet NSTextView  *selectedItemPathTextView;
  IBOutlet NSTextField  *selectedItemExactSizeField;
  IBOutlet NSTextField  *selectedItemSizeField;
  IBOutlet NSTextField  *selectedItemTitleField;

  ItemPathModel  *itemPathModel;
  DirectoryViewControlSettings  *initialSettings;
  TreeContext  *treeContext;

  NSObject <FileItemTest>  *fileItemMask;

  FileItemHashingCollection  *colorMappings;
  ColorListCollection  *colorPalettes;
  
  NSDictionary  *localizedColorMappingNamesReverseLookup;
  NSDictionary  *localizedColorPaletteNamesReverseLookup;
  
  EditFilterWindowControl  *editMaskFilterWindowControl;

  // The (absolute) path of the scan tree.
  NSString  *scanPathName;
  
  // The part of the (absolute) path that is outside the visible tree.
  NSString  *invisiblePathName;
}

- (IBAction) upAction: (id) sender;
- (IBAction) downAction: (id) sender;
- (IBAction) openFileInFinder: (id) sender;
- (IBAction) deleteFile: (id) sender;

- (IBAction) maskCheckBoxChanged: (id) sender;
- (IBAction) editMask: (id) sender;

- (IBAction) colorMappingChanged: (id) sender;
- (IBAction) colorPaletteChanged: (id) sender;
- (IBAction) showEntireVolumeCheckBoxChanged: (id) sender;

- (id) initWithTreeContext: (TreeContext *)treeContext;
- (id) initWithTreeContext: (TreeContext *)treeContext
         pathModel: (ItemPathModel *)itemPathModel
         settings: (DirectoryViewControlSettings *)settings;

- (NSObject <FileItemTest> *) fileItemMask;

- (ItemPathModel*) itemPathModel;

- (DirectoryView*) directoryView;

- (TreeContext*) treeContext;

// Returns the current settings of the view.
- (DirectoryViewControlSettings*) directoryViewControlSettings;

// TO DO: Move somewhere more appropriate?
+ (NSDictionary*) addLocalisedNamesToPopUp: (NSPopUpButton *)popUp
                    names: (NSArray *)names
                    selectName: (NSString *)defaultName
                    table: (NSString *)tableName;

@end
