#import <Cocoa/Cocoa.h>


@interface PreferencesPanelControl : NSWindowController {

  IBOutlet NSButton  *okButton;

  IBOutlet NSPopUpButton  *fileSizeMeasurePopUp;
  IBOutlet NSPopUpButton  *defaultColorMappingPopUp;
  IBOutlet NSPopUpButton  *defaultColorPalettePopUp;

  NSDictionary  *localizedFileSizeMeasureNamesReverseLookup;
  NSDictionary  *localizedColorMappingNamesReverseLookup;
  NSDictionary  *localizedColorPaletteNamesReverseLookup;
  
  NSMutableSet  *changeSet;
}

- (IBAction) cancelAction: (id)sender;
- (IBAction) okAction: (id)sender;

- (IBAction) valueChanged: (id)sender;

@end
