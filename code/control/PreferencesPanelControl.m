#import "PreferencesPanelControl.h"

#import "DirectoryViewControl.h"
#import "FileItemHashingCollection.h"
#import "ColorListCollection.h"
#import "TreeBuilder.h"

#import "UniqueTagsTransformer.h"


NSString  *FileDeletionTargetsKey = @"fileDeletionTargets";
NSString  *ConfirmFileDeletionKey = @"confirmFileDeletion";
NSString  *FileSizeMeasureKey = @"fileSizeMeasure";
NSString  *DefaultColorMappingKey = @"defaultColorMapping";
NSString  *DefaultColorPaletteKey = @"defaultColorPalette";


@interface PreferencesPanelControl (PrivateMethods)

- (void) setupPopUp: (NSPopUpButton *)popUp key: (NSString *)key
           content: (NSArray *)names;

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
  [popUps release];
  
  [super dealloc];
}


- (void) windowDidLoad {
  [[NSNotificationCenter defaultCenter]
      addObserver: self selector: @selector(windowWillClose:)
        name: NSWindowWillCloseNotification object: [self window]];

  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];

  // Configure all pop-up buttons.
  popUps = [NSMutableArray arrayWithCapacity: 4];
  [self setupPopUp: fileDeletionPopUp key: FileDeletionTargetsKey
          content: [DirectoryViewControl fileDeletionTargetNames]];
  [self setupPopUp: fileSizeMeasurePopUp key: FileSizeMeasureKey
          content: [TreeBuilder fileSizeMeasureNames]];
  [self setupPopUp: defaultColorMappingPopUp key: DefaultColorMappingKey
          content:  [[FileItemHashingCollection 
                        defaultFileItemHashingCollection] allKeys]];
  [self setupPopUp: defaultColorPalettePopUp key: DefaultColorPaletteKey
          content: [[ColorListCollection defaultColorListCollection] allKeys]];
  popUps = [[NSArray alloc] initWithArray: popUps]; // Make it immutable.

  [fileDeletionConfirmationCheckBox setState: 
     ([userDefaults boolForKey: ConfirmFileDeletionKey]
        ? NSOnState : NSOffState)];

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

  // Iterate over all pop-ups, and update prefs for those that have changed.    
  NSEnumerator  *popUpEnum = [popUps objectEnumerator];
  NSPopUpButton  *popUp;
  while (popUp = [popUpEnum nextObject]) {
    if ([changeSet containsObject: popUp]) {
      NSString  *name = [tagMaker nameForTag: [[popUp selectedItem] tag]];
      NSString  *key = [tagMaker nameForTag: [popUp tag]];

      [userDefaults setObject: name forKey: key];
    }
  }
  
  if ([changeSet containsObject: fileDeletionConfirmationCheckBox]) {
    BOOL  enabled = [fileDeletionConfirmationCheckBox state] == NSOnState;

    [userDefaults setBool: enabled forKey: ConfirmFileDeletionKey];
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

- (void) setupPopUp: (NSPopUpButton *)popUp key: (NSString *)key
           content: (NSArray *)names {
  UniqueTagsTransformer  *tagMaker = 
    [UniqueTagsTransformer defaultUniqueTagsTransformer];
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  
  // Associate the pop-up with its key in the preferences by their tag.
  [popUp setTag: [[tagMaker transformedValue: key] intValue]];

  // Initialise the pop-up with its (localized) content
  [popUp removeAllItems];
  [tagMaker addLocalisedNamesToPopUp: popUp names: names
              select: [userDefaults stringForKey: key] table: @"Names"];
              
  [((NSMutableArray *)popUps) addObject: popUp];
}

- (void) updateButtonState {
  [okButton setEnabled: [changeSet count] > 0];
  
  UniqueTagsTransformer  *tagMaker = 
    [UniqueTagsTransformer defaultUniqueTagsTransformer];
  NSString  *name = 
    [tagMaker nameForTag: [[fileDeletionPopUp selectedItem] tag]];

  [fileDeletionConfirmationCheckBox setEnabled:
    ! [name isEqualToString: DeleteNothing]];
}

@end // @implementation PreferencesPanelControl (PrivateMethods)
