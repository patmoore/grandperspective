#import <Cocoa/Cocoa.h>

@class FilterTest;
@class StringMatchControls;
@class TypeMatchControls;
@protocol NameValidator;

@interface FilterTestWindowControl : NSWindowController {

  IBOutlet NSTextField  *testNameField;
  IBOutlet NSPopUpButton  *testTargetPopUp;
  
  IBOutlet NSButton  *nameCheckBox;
  IBOutlet NSPopUpButton  *nameMatchPopUpButton;
  IBOutlet NSTableView  *nameTargetsView;
  IBOutlet NSButton  *nameCaseInsensitiveCheckBox;
  IBOutlet NSButton  *addNameTargetButton;
  IBOutlet NSButton  *removeNameTargetButton;
  
  IBOutlet NSButton  *pathCheckBox;
  IBOutlet NSPopUpButton  *pathMatchPopUpButton;
  IBOutlet NSTableView  *pathTargetsView;
  IBOutlet NSButton  *pathCaseInsensitiveCheckBox;
  IBOutlet NSButton  *addPathTargetButton;
  IBOutlet NSButton  *removePathTargetButton;
  
  IBOutlet NSButton  *hardLinkCheckBox;
  IBOutlet NSPopUpButton  *hardLinkStatusPopUp;

  IBOutlet NSButton  *packageCheckBox;
  IBOutlet NSPopUpButton  *packageStatusPopUp;

  IBOutlet NSButton  *typeCheckBox;
  IBOutlet NSPopUpButton  *typeMatchPopUpButton;
  IBOutlet NSTableView  *typeTargetsView;
  IBOutlet NSButton  *addTypeTargetButton;
  IBOutlet NSButton  *removeTypeTargetButton;
  
  IBOutlet NSButton  *sizeLowerBoundCheckBox;
  IBOutlet NSTextField  *sizeLowerBoundField;
  IBOutlet NSPopUpButton  *sizeLowerBoundUnits;

  IBOutlet NSButton  *sizeUpperBoundCheckBox;
  IBOutlet NSTextField  *sizeUpperBoundField;
  IBOutlet NSPopUpButton  *sizeUpperBoundUnits;

  IBOutlet NSButton  *cancelButton;
  IBOutlet NSButton  *okButton;
  
  NSString  *testName;
  NSObject <NameValidator>  *nameValidator;
  // Set to the last name (if any) that has been reported invalid.
  NSString  *invalidName;
    
  // Indicates iff an "okPerformed", "cancelPerformed" or "closePerformed"
  // notification has been fired already.
  BOOL  finalNotificationFired;
  
  TypeMatchControls  *typeTestControls;
  StringMatchControls  *nameTestControls;
  StringMatchControls  *pathTestControls;
}

+ (id) defaultInstance;

- (IBAction) testNameChanged:(id) sender;
- (IBAction) sizeBoundEntered:(id) sender;

- (IBAction) targetPopUpChanged:(id) sender;

- (IBAction) nameCheckBoxChanged:(id) sender;
- (IBAction) pathCheckBoxChanged:(id) sender;
- (IBAction) hardLinkCheckBoxChanged:(id) sender;
- (IBAction) packageCheckBoxChanged:(id) sender;
- (IBAction) typeCheckBoxChanged:(id) sender;
- (IBAction) lowerBoundCheckBoxChanged:(id) sender;
- (IBAction) upperBoundCheckBoxChanged:(id) sender;

- (IBAction) addNameTarget:(id) sender;
- (IBAction) removeNameTarget:(id) sender;

- (IBAction) addPathTarget:(id) sender;
- (IBAction) removePathTarget:(id) sender;

- (IBAction) addTypeTarget:(id) sender;
- (IBAction) removeTypeTarget:(id) sender;

- (IBAction) cancelAction:(id) sender;
- (IBAction) okAction:(id) sender;

- (NSString *)fileItemTestName;

- (void) setNameValidator:(NSObject<NameValidator> *)validator;

/* Configures the window to represent the given test.
 */
- (void) representFilterTest:(FilterTest *)test;

/* Creates the filter test that represents the current window state.
 */
- (FilterTest *)createFilterTest;

/* Sets the name of the filter test as it is shown in the window. This may be
 * different from the actual name of the test (in particular, the visible
 * name may be localized). Once a visible name is set, it cannot be changed.
 */
- (void) setVisibleName:(NSString *)name;

@end
