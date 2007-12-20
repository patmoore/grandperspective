#import "PreferencesPanelControl.h"

#import "DirectoryViewControl.h"
#import "FileItemHashingCollection.h"
#import "ColorListCollection.h"
#import "FileSizeMeasureCollection.h"

#import "UniqueTagsTransformer.h"


NSString  *FileDeletionTargetsKey = @"fileDeletionTargets";
NSString  *ConfirmFileDeletionKey = @"confirmFileDeletion";
NSString  *FileSizeMeasureKey = @"fileSizeMeasure";
NSString  *DefaultColorMappingKey = @"defaultColorMapping";
NSString  *DefaultColorPaletteKey = @"defaultColorPalette";


@interface PreferencesPanelControl (PrivateMethods)

- (void) updateButtonState;

@end

@implementation PreferencesPanelControl

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) init {
  if (self = [super initWithWindowNibName: @"PreferencesPanel" owner: self]) {
    changeSet = [[NSMutableSet alloc] initWithCapacity: 8];
    
    // Trigger loading of the window
    [self window];
  }

  return self;
}

- (void) dealloc {
  [changeSet release];
  
  [super dealloc];
}


- (void) windowDidLoad {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  
  [[NSNotificationCenter defaultCenter]
      addObserver: self selector: @selector(windowWillClose:)
        name: NSWindowWillCloseNotification object: [self window]];

  FileItemHashingCollection  *colorMappings = 
      [FileItemHashingCollection defaultFileItemHashingCollection];
  ColorListCollection  *colorPalettes = 
      [ColorListCollection defaultColorListCollection];
  FileSizeMeasureCollection  *fileSizeMeasures = 
      [FileSizeMeasureCollection defaultFileSizeMeasureCollection];
      
  UniqueTagsTransformer  *tagMaker = 
    [UniqueTagsTransformer defaultUniqueTagsTransformer];

  [fileDeletionPopUp removeAllItems];
  [tagMaker addLocalisedNamesToPopUp: fileDeletionPopUp
              names: [DirectoryViewControl fileDeletionTargetNames]
              select: [userDefaults stringForKey: FileDeletionTargetsKey]
              table: @"Names"];

  [fileDeletionConfirmationCheckBox setState: 
     ([userDefaults boolForKey: ConfirmFileDeletionKey]
        ? NSOnState : NSOffState)];

  [fileSizeMeasurePopUp removeAllItems];
  [tagMaker addLocalisedNamesToPopUp: fileSizeMeasurePopUp
              names: [fileSizeMeasures allKeys]
              select: [userDefaults stringForKey: FileSizeMeasureKey]
              table: @"Names"];

  [defaultColorMappingPopUp removeAllItems];  
  [tagMaker addLocalisedNamesToPopUp: defaultColorMappingPopUp
              names: [colorMappings allKeys]
              select: [userDefaults stringForKey: DefaultColorMappingKey]
              table: @"Names"];

  [defaultColorPalettePopUp removeAllItems];
  [tagMaker addLocalisedNamesToPopUp: defaultColorPalettePopUp
              names: [colorPalettes allKeys]
              select: [userDefaults stringForKey: DefaultColorPaletteKey] 
              table: @"Names"];

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
  UniqueTagsTransformer  *tagMaker = 
    [UniqueTagsTransformer defaultUniqueTagsTransformer];

  if ([changeSet containsObject: fileDeletionPopUp]) {
    NSString  *name = [tagMaker nameForItem: [fileDeletionPopUp selectedItem]];

    [userDefaults setObject: name forKey: FileDeletionTargetsKey];
  }
  
  if ([changeSet containsObject: fileDeletionConfirmationCheckBox]) {
    BOOL  enabled = [fileDeletionConfirmationCheckBox state] == NSOnState;

    [userDefaults setBool: enabled forKey: ConfirmFileDeletionKey];
  }

  if ([changeSet containsObject: fileSizeMeasurePopUp]) {
    NSString  *name = 
      [tagMaker nameForItem: [fileSizeMeasurePopUp selectedItem]];

    [userDefaults setObject: name forKey: FileSizeMeasureKey];
  }

  if ([changeSet containsObject: defaultColorMappingPopUp]) {
    NSString  *name = 
      [tagMaker nameForItem: [defaultColorMappingPopUp selectedItem]];

    [userDefaults setObject: name forKey: DefaultColorMappingKey];
  }
  
  if ([changeSet containsObject: defaultColorPalettePopUp]) {
    NSString  *name =  
      [tagMaker nameForItem: [defaultColorPalettePopUp selectedItem]];
    
    [userDefaults setObject: name forKey: DefaultColorPaletteKey];
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
  
  UniqueTagsTransformer  *tagMaker = 
    [UniqueTagsTransformer defaultUniqueTagsTransformer];
  NSString  *name = [tagMaker nameForItem: [fileDeletionPopUp selectedItem]];

  [fileDeletionConfirmationCheckBox setEnabled:
    ! [name isEqualToString: DeleteNothing]];
}

@end // @implementation PreferencesPanelControl (PrivateMethods)
