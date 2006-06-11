#import <Cocoa/Cocoa.h>

@class FileItem;
@class DirectoryView;
@class StartupControl;
@class ItemPathModel;
@class FileItemHashingOptions;
@class FileItemHashing;
@class EditFilterWindowControl;

@interface DirectoryViewControl : NSWindowController {

  IBOutlet NSComboBox  *colorMappingChoice;
  IBOutlet NSTextField  *itemNameLabel;
  IBOutlet NSTextField  *itemSizeLabel;
  IBOutlet DirectoryView  *mainView;
  IBOutlet NSButton  *upButton;
  IBOutlet NSButton  *downButton;
  IBOutlet NSButton  *openButton;

  FileItem  *itemTreeRoot;
  ItemPathModel  *itemPathModel;

  FileItemHashingOptions  *hashingOptions;
  NSString  *initialHashingOptionKey;
  
  EditFilterWindowControl  *editMaskFilterWindowControl;

  NSString  *invisiblePathName;
}

- (IBAction) upAction:(id)sender;
- (IBAction) downAction:(id)sender;
- (IBAction) openFileInFinder:(id)sender;
- (IBAction) maskAction:(id)sender;
- (IBAction) colorMappingChanged:(id)sender;

- (id) initWithItemTree:(FileItem*)itemTreeRoot;
- (id) initWithItemTree:(FileItem*)itemTreeRoot 
         itemPathModel:(ItemPathModel*)itemPathModel
         fileItemHashingKey:(NSString*)fileItemHashingKey;

- (FileItem*) itemTree;

- (NSString*) fileItemHashingKey;
- (FileItemHashing*) fileItemHashing;

- (ItemPathModel*) itemPathModel;

- (DirectoryView*) directoryView;

- (EditFilterWindowControl*) editMaskFilterWindowControl;

@end
