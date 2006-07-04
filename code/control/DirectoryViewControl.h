#import <Cocoa/Cocoa.h>

@class DirectoryItem;
@class DirectoryView;
@class StartupControl;
@class ItemPathModel;
@class FileItemHashingOptions;
@class FileItemHashing;
@class EditFilterWindowControl;
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

  DirectoryItem  *itemTreeRoot;
  ItemPathModel  *itemPathModel;
  
  NSObject <FileItemTest>  *fileItemMask;

  FileItemHashingOptions  *hashingOptions;
  NSString  *initialHashingOptionKey;
  
  EditFilterWindowControl  *editMaskFilterWindowControl;

  NSString  *invisiblePathName;
}

- (IBAction) upAction:(id)sender;
- (IBAction) downAction:(id)sender;
- (IBAction) openFileInFinder:(id)sender;

- (IBAction) maskCheckBoxChanged:(id)sender;
- (IBAction) maskAction:(id)sender;

- (IBAction) colorMappingChanged:(id)sender;

- (id) initWithItemTree:(DirectoryItem*)itemTreeRoot;
- (id) initWithItemTree:(DirectoryItem*)itemTreeRoot 
         itemPathModel:(ItemPathModel*)itemPathModel
         fileItemHashingKey:(NSString*)fileItemHashingKey;

- (DirectoryItem*) itemTree;

- (NSString*) fileItemHashingKey;
- (FileItemHashing*) fileItemHashing;

- (NSObject <FileItemTest> *) fileItemMask;
- (void) setFileItemMask:(NSObject <FileItemTest> *) mask;

- (BOOL) fileItemMaskEnabled;
- (void) enableFileItemMask:(BOOL) flag;

- (ItemPathModel*) itemPathModel;

- (DirectoryView*) directoryView;

@end
