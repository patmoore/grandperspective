#import <Cocoa/Cocoa.h>

@class DirectoryItem;
@class DirectoryView;
@class StartupControl;
@class ItemPathModel;
@class FileItemHashing;
@class FileItemHashingCollection;
@class ColorListCollection;
@class EditFilterWindowControl;
@class DirectoryViewControlSettings;
@class TreeHistory;
@protocol FileItemTest;

@interface DirectoryViewControl : NSWindowController {

  // Main window
  IBOutlet NSTextField  *itemPathField;
  IBOutlet NSTextField  *itemSizeField;
  IBOutlet DirectoryView  *mainView;
  IBOutlet NSButton  *upButton;
  IBOutlet NSButton  *downButton;
  IBOutlet NSButton  *openButton;
  
  IBOutlet NSDrawer  *drawer;
  
  // "Display" drawer panel
  IBOutlet NSPopUpButton  *colorMappingPopUp;
  IBOutlet NSPopUpButton  *colorPalettePopUp;
  IBOutlet NSTextView  *maskDescriptionTextView;
  IBOutlet NSButton  *maskCheckBox;

  // "Info" drawer panel
  IBOutlet NSTextView  *treePathTextView;
  IBOutlet NSTextField  *filterNameField;
  IBOutlet NSTextView  *filterDescriptionTextView;
  IBOutlet NSTextField  *scanTimeField;
  IBOutlet NSTextField  *treeSizeField;
  
  // "Focus" drawer panel
  IBOutlet NSTextView  *visibleFolderPathTextView;
  IBOutlet NSTextField  *visibleFolderSizeField;
  IBOutlet NSTextView  *selectedFilePathTextView;
  IBOutlet NSTextField  *selectedFileSizeField;

  ItemPathModel  *itemPathModel;
  DirectoryViewControlSettings  *initialSettings;
  TreeHistory  *treeHistory;

  NSObject <FileItemTest>  *fileItemMask;

  FileItemHashingCollection  *colorMappings;
  ColorListCollection  *colorPalettes;
  
  NSDictionary  *localisedColorMappingNamesReverseLookup;
  NSDictionary  *localisedColorPaletteNamesReverseLookup;
  
  EditFilterWindowControl  *editMaskFilterWindowControl;

  NSString  *invisiblePathName;
}

- (IBAction) upAction: (id) sender;
- (IBAction) downAction: (id) sender;
- (IBAction) openFileInFinder: (id) sender;

- (IBAction) maskCheckBoxChanged: (id) sender;
- (IBAction) editMask: (id) sender;

- (IBAction) colorMappingChanged: (id) sender;
- (IBAction) colorPaletteChanged: (id) sender;

- (id) initWithItemTree: (DirectoryItem *)itemTreeRoot;
- (id) initWithItemPathModel: (ItemPathModel *)itemPathModel
         history: (TreeHistory *)history
         settings: (DirectoryViewControlSettings *)settings;

- (FileItemHashing*) colorMapping;

- (NSObject <FileItemTest> *) fileItemMask;
- (BOOL) fileItemMaskEnabled;

- (ItemPathModel*) itemPathModel;

- (DirectoryView*) directoryView;

- (TreeHistory*) treeHistory;

// Returns the current settings of the view.
- (DirectoryViewControlSettings*) directoryViewControlSettings;

// TO DO: Move somewhere more appropriate?
+ (NSDictionary*) addLocalisedNamesToPopUp: (NSPopUpButton *)popUp
                    names: (NSArray *)names
                    selectName: (NSString *)defaultName
                    table: (NSString *)tableName;

@end
