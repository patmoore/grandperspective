#import "PreferencesPanelControl.h"

#import "DirectoryViewControl.h"
#import "FileItemHashingCollection.h"
#import "ColorListCollection.h"


@interface PreferencesPanelControl (PrivateMethods)

- (void) updateButtonState;

@end

@implementation PreferencesPanelControl

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) init {
  if (self = [super initWithWindowNibName: @"PreferencesPanel" owner: self]) {
    defaultColorMappingChanged = NO;
    defaultColorPaletteChanged = NO;
    
    // Trioger loading of the window
    [self window];
  }

  return self;
}

- (void) dealloc {
  NSLog(@"PreferencesPanelControl-dealloc");

  [localizedColorMappingNamesReverseLookup release];
  [localizedColorPaletteNamesReverseLookup release];
  
  [super dealloc];
}


- (void) windowDidLoad {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  
  [[NSNotificationCenter defaultCenter]
      addObserver:self selector:@selector(windowWillClose:)
      name:@"NSWindowWillCloseNotification" object:[self window]];

  FileItemHashingCollection  *colorMappings = 
      [[FileItemHashingCollection defaultFileItemHashingCollection] retain];
  ColorListCollection  *colorPalettes = 
      [[ColorListCollection defaultColorListCollection] retain];
  
  [defaultColorMappingPopUp removeAllItems];  
  localizedColorMappingNamesReverseLookup =
    [[DirectoryViewControl
        addLocalisedNamesToPopUp: defaultColorMappingPopUp
        names: [colorMappings allKeys]
        selectName: [userDefaults stringForKey: @"defaultColorMapping"]
        table: @"MappingNames"] retain];

  [defaultColorPalettePopUp removeAllItems];
  localizedColorPaletteNamesReverseLookup =
    [[DirectoryViewControl
        addLocalisedNamesToPopUp: defaultColorPalettePopUp
        names: [colorPalettes allKeys]
        selectName: [userDefaults stringForKey: @"defaultColorPalette"] 
        table: @"PaletteNames"] retain];

  [self updateButtonState];
  
  [[self window] center];
  [[self window] makeKeyAndOrderFront: self];
}


- (void) windowWillClose:(NSNotification*)notification {
   [self autorelease];
}


- (IBAction) cancelAction: (id)sender {
  [[self window] close];
}

- (IBAction) okAction: (id)sender {
  [[self window] close];

  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];

  if (defaultColorMappingChanged) {
    NSString  *localizedName = [defaultColorMappingPopUp titleOfSelectedItem];
    NSString  *name = 
      [localizedColorMappingNamesReverseLookup objectForKey: localizedName];

    [userDefaults setObject: name forKey: @"defaultColorMapping"];
    
    defaultColorMappingChanged = NO;
  }
  
  if (defaultColorPaletteChanged) {
    NSString  *localizedName = [defaultColorPalettePopUp titleOfSelectedItem];
    NSString  *name = 
      [localizedColorPaletteNamesReverseLookup objectForKey: localizedName];
    
    [userDefaults setObject: name forKey: @"defaultColorPalette"];
      
    defaultColorPaletteChanged = NO;
  }
  
  [self updateButtonState];
}


- (IBAction) defaultColorMappingChanged: (id) sender {
  defaultColorMappingChanged = YES;
  [self updateButtonState];
}

- (IBAction) defaultColorPaletteChanged: (id) sender {
  defaultColorPaletteChanged = YES;
  [self updateButtonState];
}

@end // @implementation PreferencesPanelControl


@implementation PreferencesPanelControl (PrivateMethods)

- (void) updateButtonState {
  [okButton setEnabled: (defaultColorMappingChanged || 
                         defaultColorPaletteChanged)];
}

@end // @implementation PreferencesPanelControl (PrivateMethods)
