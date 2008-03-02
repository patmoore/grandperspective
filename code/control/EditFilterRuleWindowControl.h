#import <Cocoa/Cocoa.h>

@protocol FileItemTest;
@class StringBasedTestControls;

@interface EditFilterRuleWindowControl : NSWindowController {

  IBOutlet NSTextField  *ruleNameField;
  
  IBOutlet NSButton  *nameCheckBox;
  IBOutlet NSPopUpButton  *nameMatchPopUpButton;
  IBOutlet NSTextView  *nameTargetsView;
  IBOutlet NSButton  *nameCaseInsensitiveCheckBox;
  
  IBOutlet NSButton  *pathCheckBox;
  IBOutlet NSPopUpButton  *pathMatchPopUpButton;
  IBOutlet NSTextView  *pathTargetsView;
  IBOutlet NSButton  *pathCaseInsensitiveCheckBox;
  
  IBOutlet NSButton  *sizeLowerBoundCheckBox;
  IBOutlet NSTextField  *sizeLowerBoundField;
  IBOutlet NSPopUpButton  *sizeLowerBoundUnits;

  IBOutlet NSButton  *sizeUpperBoundCheckBox;
  IBOutlet NSTextField  *sizeUpperBoundField;
  IBOutlet NSPopUpButton  *sizeUpperBoundUnits;

  IBOutlet NSButton  *doneButton;
  
  NSString  *ruleName;
  
  StringBasedTestControls  *nameTestControls;
  StringBasedTestControls  *pathTestControls;
}

+ (id) defaultInstance;

- (IBAction) valueEntered:(id)sender;

- (IBAction) nameCheckBoxChanged:(id)sender;
- (IBAction) pathCheckBoxChanged:(id)sender;
- (IBAction) lowerBoundCheckBoxChanged:(id)sender;
- (IBAction) upperBoundCheckBoxChanged:(id)sender;

- (IBAction) updateEnabledState:(id)sender;

- (IBAction) cancelAction:(id)sender;
- (IBAction) okAction:(id)sender;

- (NSString*) fileItemTestName;

// Configures the window to represent the given test.
- (void) representFileItemTest:(NSObject <FileItemTest> *)test;

// Creates the test object that represents the current window state.
- (NSObject <FileItemTest> *) createFileItemTest;

/* Sets the name of the rule as it is shown in the window. This may be
 * different from the actual name of the rule (in particular, the visible
 * name may be localized). Once a visible name is set, it cannot be changed.
 */
- (void) setVisibleName: (NSString *)name;

@end
