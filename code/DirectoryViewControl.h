#import <Cocoa/Cocoa.h>

@class FileItem;
@class DirectoryView;
@class StartupControl;
@class ItemPathModel;
@class FileItemHashingOptions;
@class FileItemHashing;

@interface DirectoryViewControl : NSWindowController {

  IBOutlet NSComboBox *colorMappingChoice;
  IBOutlet NSTextField *itemNameLabel;
  IBOutlet NSTextField *itemSizeLabel;
  IBOutlet DirectoryView *mainView;
  IBOutlet NSButton *upButton;
  IBOutlet NSButton *downButton;

  FileItem  *itemTreeRoot;
  ItemPathModel  *itemPathModel;

  FileItemHashingOptions  *hashingOptions;
  NSString  *initialHashingOptionKey;

  NSMutableString  *invisiblePathName;
}

- (IBAction) colorMappingChanged:(id)sender;
- (IBAction) upAction:(id)sender;
- (IBAction) downAction:(id)sender;

- (id) initWithItemTree:(FileItem*)itemTreeRoot;
- (id) initWithItemTree:(FileItem*)itemTreeRoot 
         itemPathModel:(ItemPathModel*)itemPathModel
         fileItemHashingKey:(NSString*)fileItemHashingKey;

- (FileItem*) itemTree;

- (NSString*) fileItemHashingKey;

- (ItemPathModel*) itemPathModel;


@end
