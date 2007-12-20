#import <Cocoa/Cocoa.h>


extern NSString  *FileDeletionTargetsKey;
extern NSString  *ConfirmFileDeletionKey;
extern NSString  *FileSizeMeasureKey;
extern NSString  *DefaultColorMappingKey;
extern NSString  *DefaultColorPaletteKey;


@interface PreferencesPanelControl : NSWindowController {

  IBOutlet NSButton  *okButton;

  IBOutlet NSPopUpButton  *fileDeletionPopUp;
  IBOutlet NSButton  *fileDeletionConfirmationCheckBox;
  
  IBOutlet NSPopUpButton  *fileSizeMeasurePopUp;

  IBOutlet NSPopUpButton  *defaultColorMappingPopUp;
  IBOutlet NSPopUpButton  *defaultColorPalettePopUp;

  NSMutableSet  *changeSet;
}

- (IBAction) cancelAction: (id)sender;
- (IBAction) okAction: (id)sender;

- (IBAction) valueChanged: (id)sender;

@end
