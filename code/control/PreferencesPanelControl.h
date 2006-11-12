#import <Cocoa/Cocoa.h>


@interface PreferencesPanelControl : NSWindowController {

  IBOutlet NSButton  *okButton;

  IBOutlet NSPopUpButton  *defaultColorMappingPopUp;
  IBOutlet NSPopUpButton  *defaultColorPalettePopUp;

  NSDictionary  *localisedColorMappingNamesReverseLookup;
  NSDictionary  *localisedColorPaletteNamesReverseLookup;
  
  BOOL  defaultColorMappingChanged;
  BOOL  defaultColorPaletteChanged;
}

- (IBAction) cancelAction: (id)sender;
- (IBAction) okAction: (id)sender;

- (IBAction) defaultColorMappingChanged: (id)sender;
- (IBAction) defaultColorPaletteChanged: (id)sender;

@end
