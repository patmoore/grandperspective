#import <Cocoa/Cocoa.h>

@class DirectoryItem;
@class DirectoryView;
@class StartupControl;
@class ItemPathModel;
@class FileItemHashingOptions;
@class FileItemHashing;
@class EditFilterWindowControl;
@class DirectoryViewControlSettings;
@class TreeHistory;
@protocol FileItemTest;

@interface DirectoryViewControl : NSWindowController {

  IBOutlet NSPopUpButton  *colorMappingPopUp;
  IBOutlet NSTextField  *itemNameLabel;
  IBOutlet NSTextField  *itemSizeLabel;
  IBOutlet DirectoryView  *mainView;
  IBOutlet NSButton  *upButton;
  IBOutlet NSButton  *downButton;
  IBOutlet NSButton  *openButton;
  IBOutlet NSButton  *maskCheckBox;

  ItemPathModel  *itemPathModel;
  DirectoryViewControlSettings  *initialSettings;
  TreeHistory  *treeHistory;

  NSObject <FileItemTest>  *fileItemMask;

  FileItemHashingOptions  *hashingOptions;
  
  EditFilterWindowControl  *editMaskFilterWindowControl;

  NSString  *invisiblePathName;
}

- (IBAction) upAction:(id)sender;
- (IBAction) downAction:(id)sender;
- (IBAction) openFileInFinder:(id)sender;

- (IBAction) maskCheckBoxChanged:(id)sender;
- (IBAction) maskAction:(id)sender;

- (IBAction) colorMappingChanged:(id)sender;

- (id) initWithItemTree: (DirectoryItem *)itemTreeRoot;
- (id) initWithItemPathModel: (ItemPathModel *)itemPathModel
         history: (TreeHistory *)history
         settings: (DirectoryViewControlSettings *)settings;

- (FileItemHashing*) fileItemHashing;

- (NSObject <FileItemTest> *) fileItemMask;
- (BOOL) fileItemMaskEnabled;

- (ItemPathModel*) itemPathModel;

- (DirectoryView*) directoryView;

- (TreeHistory*) treeHistory;

// Returns the current settings of the view.
- (DirectoryViewControlSettings*) directoryViewControlSettings;

@end
