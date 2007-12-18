#import <Cocoa/Cocoa.h>


extern NSString  *PreferencesChangedEvent;

extern NSString  *FileDeletionTargetsKey;
extern NSString  *ConfirmFileDeletionKey;


@interface PreferencesPanelControl : NSWindowController {

  IBOutlet NSButton  *okButton;

  IBOutlet NSPopUpButton  *fileDeletionPopUp;
  IBOutlet NSButton  *fileDeletionConfirmationCheckBox;
  
  IBOutlet NSPopUpButton  *fileSizeMeasurePopUp;

  IBOutlet NSPopUpButton  *defaultColorMappingPopUp;
  IBOutlet NSPopUpButton  *defaultColorPalettePopUp;

  NSDictionary  *localizedFileDeletionTargetNamesReverseLookup;
  NSDictionary  *localizedFileSizeMeasureNamesReverseLookup;
  NSDictionary  *localizedColorMappingNamesReverseLookup;
  NSDictionary  *localizedColorPaletteNamesReverseLookup;
  
  NSMutableSet  *changeSet;
}

- (IBAction) cancelAction: (id)sender;
- (IBAction) okAction: (id)sender;

- (IBAction) valueChanged: (id)sender;

@end
