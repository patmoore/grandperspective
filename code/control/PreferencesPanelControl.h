#import <Cocoa/Cocoa.h>


extern NSString  *FileDeletionTargetsKey;
extern NSString  *ConfirmFileDeletionKey;
extern NSString  *ConfirmFolderDeletionKey;
extern NSString  *RescanBehaviourKey;
extern NSString  *FileSizeMeasureKey;
extern NSString  *DefaultColorMappingKey;
extern NSString  *DefaultColorPaletteKey;
extern NSString  *DefaultColorGradient;
extern NSString  *ShowPackageContentsByDefaultKey;
extern NSString  *ProgressPanelRefreshRateKey;
extern NSString  *DefaultViewWindowWidth;
extern NSString  *DefaultViewWindowHeight;
extern NSString  *CustomFileOpenApplication;
extern NSString  *CustomFileRevealApplication;
extern NSString  *UpdateFiltersBeforeUse;

@class EditUniformTypeRankingWindowControl;

@interface PreferencesPanelControl : NSWindowController {

  IBOutlet NSPopUpButton  *fileDeletionPopUp;
  IBOutlet NSButton  *fileDeletionConfirmationCheckBox;
  
  IBOutlet NSPopUpButton  *rescanBehaviourPopUp;
  
  IBOutlet NSPopUpButton  *fileSizeMeasurePopUp;

  IBOutlet NSPopUpButton  *defaultColorMappingPopUp;
  IBOutlet NSPopUpButton  *defaultColorPalettePopUp;
  
  IBOutlet NSButton  *showPackageContentsByDefaultCheckBox;
  
  EditUniformTypeRankingWindowControl  *uniformTypeWindowControl;
}

- (IBAction) popUpValueChanged: (id)sender;

- (IBAction) valueChanged: (id)sender;

- (IBAction) editUniformTypeRanking: (id) sender;

@end
