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
    changeSet = [[NSMutableSet alloc] initWithCapacity: 4];
    
    // Trigger loading of the window
    [self window];
  }

  return self;
}

- (void) dealloc {
  NSLog(@"PreferencesPanelControl-dealloc");

  [localizedColorMappingNamesReverseLookup release];
  [localizedColorPaletteNamesReverseLookup release];
  
  [changeSet release];
  
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

  [fileSizeTypePopUp removeAllItems];
  localizedFileSizeTypesReverseLookup =
    [[DirectoryViewControl
        addLocalisedNamesToPopUp: fileSizeTypePopUp
        names: [NSArray arrayWithObjects: @"logical", @"physical", nil]
        selectName: [userDefaults stringForKey: @"fileSizeType"]
        table: @"Names"] retain];

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

  if ([changeSet containsObject: fileSizeTypePopUp]) {
    NSString  *localizedName = [fileSizeTypePopUp titleOfSelectedItem];
    NSString  *name = 
      [localizedFileSizeTypesReverseLookup objectForKey: localizedName];

    [userDefaults setObject: name forKey: @"fileSizeType"];
  }

  if ([changeSet containsObject: defaultColorMappingPopUp]) {
    NSString  *localizedName = [defaultColorMappingPopUp titleOfSelectedItem];
    NSString  *name = 
      [localizedColorMappingNamesReverseLookup objectForKey: localizedName];

    [userDefaults setObject: name forKey: @"defaultColorMapping"];
  }
  
  if ([changeSet containsObject: defaultColorPalettePopUp]) {
    NSString  *localizedName = [defaultColorPalettePopUp titleOfSelectedItem];
    NSString  *name = 
      [localizedColorPaletteNamesReverseLookup objectForKey: localizedName];
    
    [userDefaults setObject: name forKey: @"defaultColorPalette"];
  }
  
  [changeSet removeAllObjects];
  
  [self updateButtonState];
}


- (IBAction) valueChanged: (id) sender {
  [changeSet addObject: sender];

  [self updateButtonState];
}

@end // @implementation PreferencesPanelControl


@implementation PreferencesPanelControl (PrivateMethods)

- (void) updateButtonState {
  [okButton setEnabled: [changeSet count] > 0];
}

@end // @implementation PreferencesPanelControl (PrivateMethods)
