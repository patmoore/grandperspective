#import "PreferencesPanelControl.h"

#import "DirectoryViewControl.h"
#import "FileItemMappingCollection.h"
#import "ColorListCollection.h"
#import "TreeBuilder.h"

#import "EditUniformTypeRankingWindowControl.h"

#import "UniqueTagsTransformer.h"


NSString  *FileDeletionTargetsKey = @"fileDeletionTargets";
NSString  *ConfirmFileDeletionKey = @"confirmFileDeletion";
NSString  *FileSizeMeasureKey = @"fileSizeMeasure";
NSString  *DefaultColorMappingKey = @"defaultColorMapping";
NSString  *DefaultColorPaletteKey = @"defaultColorPalette";
NSString  *ShowPackageContentsByDefaultKey = @"showPackageContentsByDefault";


/* Note: The preferences below cannot currently be changed from the 
 * preferences panel; they can only be controlled by way of the application 
 * defaults.
 */
NSString  *ConfirmFolderDeletionKey = @"confirmFolderDeletion";
NSString  *ProgressPanelRefreshRateKey = @"progressPanelRefreshRate";
NSString  *DefaultViewWindowWidth = @"defaultViewWindowWidth";
NSString  *DefaultViewWindowHeight = @"defaultViewWindowHeight";


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
    // Trigger loading of the window
    [self window];
  }

  return self;
}

- (void) dealloc {
  [uniformTypeWindowControl release];
  
  [super dealloc];
}


- (void) windowDidLoad {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];

  // Configure all pop-up buttons.
  [self setupPopUp: fileDeletionPopUp key: FileDeletionTargetsKey
          content: [DirectoryViewControl fileDeletionTargetNames]];
  [self setupPopUp: fileSizeMeasurePopUp key: FileSizeMeasureKey
          content: [TreeBuilder fileSizeMeasureNames]];
  [self setupPopUp: defaultColorMappingPopUp key: DefaultColorMappingKey
          content:  [[FileItemMappingCollection 
                        defaultFileItemMappingCollection] allKeys]];
  [self setupPopUp: defaultColorPalettePopUp key: DefaultColorPaletteKey
          content: [[ColorListCollection defaultColorListCollection] allKeys]];
  
  [fileDeletionConfirmationCheckBox setState: 
     ([userDefaults boolForKey: ConfirmFileDeletionKey]
        ? NSOnState : NSOffState)];
  [showPackageContentsByDefaultCheckBox setState: 
     ([userDefaults boolForKey: ShowPackageContentsByDefaultKey]
        ? NSOnState : NSOffState)];

  [self updateButtonState];
  
  [[self window] center];
}


- (IBAction) popUpValueChanged: (id)sender {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  UniqueTagsTransformer  *tagMaker = 
    [UniqueTagsTransformer defaultUniqueTagsTransformer];

  NSPopUpButton  *popUp = sender;
  NSString  *name = [tagMaker nameForTag: [[popUp selectedItem] tag]];
  NSString  *key = [tagMaker nameForTag: [popUp tag]];

  [userDefaults setObject: name forKey: key];
  
  if (popUp == fileDeletionPopUp) {
    [self updateButtonState];
  }
}

- (IBAction) valueChanged: (id) sender {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];

  if (sender == fileDeletionConfirmationCheckBox) {
    BOOL  enabled = [sender state] == NSOnState;

    [userDefaults setBool: enabled forKey: ConfirmFileDeletionKey];
  }
  else if (sender == showPackageContentsByDefaultCheckBox) {
    BOOL  enabled = [sender state] == NSOnState;
    
    [userDefaults setBool: enabled forKey: ShowPackageContentsByDefaultKey];
  }
  else {
    NSAssert(NO, @"Unexpected sender for -valueChanged.");
  }
}

- (IBAction) editUniformTypeRanking: (id) sender {
  if (uniformTypeWindowControl == nil) {
    // Lazily construct the window
    uniformTypeWindowControl = 
      [[EditUniformTypeRankingWindowControl alloc] init];
  }
  
  // [uniformTypeWindowControl refreshTypeList];
  [[uniformTypeWindowControl window] makeKeyAndOrderFront: self];
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
}

- (void) updateButtonState {
  UniqueTagsTransformer  *tagMaker = 
    [UniqueTagsTransformer defaultUniqueTagsTransformer];
  NSString  *name = 
    [tagMaker nameForTag: [[fileDeletionPopUp selectedItem] tag]];

  [fileDeletionConfirmationCheckBox setEnabled:
    ! [name isEqualToString: DeleteNothing]];
}

@end // @implementation PreferencesPanelControl (PrivateMethods)
