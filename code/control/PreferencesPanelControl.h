#import <Cocoa/Cocoa.h>


extern NSString  *FileDeletionTargetsKey;
extern NSString  *ConfirmFileDeletionKey;
extern NSString  *ConfirmFolderDeletionKey;
extern NSString  *FileSizeMeasureKey;
extern NSString  *DefaultColorMappingKey;
extern NSString  *DefaultColorPaletteKey;
extern NSString  *ShowPackageContentsKey;


@class EditUniformTypeRankingWindowControl;

@interface PreferencesPanelControl : NSWindowController {

  IBOutlet NSPopUpButton  *fileDeletionPopUp;
  IBOutlet NSButton  *fileDeletionConfirmationCheckBox;
  
  IBOutlet NSPopUpButton  *fileSizeMeasurePopUp;

  IBOutlet NSPopUpButton  *defaultColorMappingPopUp;
  IBOutlet NSPopUpButton  *defaultColorPalettePopUp;
  
  IBOutlet NSButton  *showPackageContentsCheckBox;
  
  EditUniformTypeRankingWindowControl  *uniformTypeWindowControl;
}

- (IBAction) popUpValueChanged: (id)sender;

- (IBAction) valueChanged: (id)sender;

- (IBAction) editUniformTypeRanking: (id) sender;

@end
