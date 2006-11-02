#import <Cocoa/Cocoa.h>

@class EditFilterRuleWindowControl;
@class NotifyingDictionary;
@class FileItemTestRepository;
@protocol FileItemTest;

/**
 * A control for an EditFilterWindow.
 *
 * The control fires "okPerformed", "cancelPerformed", "applyPerformed", and
 * "closePerformed" notifications to signal that respectively the OK, Cancel,
 * Apply and Close buttons have been pressed. This allows the window to be run 
 * modally (e.g. when used to apply a Filter from the main menu), as well as 
 * normally (e.g. when used to set/change a mask for a specific directory
 * view window).
 */
@interface EditFilterWindowControl : NSWindowController {

  IBOutlet NSPopUpButton  *filterActionButton;

  IBOutlet NSTextView  *testDescriptionView;
  IBOutlet NSDrawer  *testDescriptionDrawer;
  
  IBOutlet NSButton  *applyButton;
  IBOutlet NSButton  *okButton;

  IBOutlet NSButton  *removeTestFromRepositoryButton;
  IBOutlet NSButton  *editTestInRepositoryButton;

  IBOutlet NSButton  *addTestToFilterButton;
  IBOutlet NSButton  *removeTestFromFilterButton;
  
  IBOutlet NSBrowser  *filterTestsBrowser;
  IBOutlet NSBrowser  *availableTestsBrowser;
  
  NotifyingDictionary  *repositoryTestsByName;
  NSMutableDictionary  *filterTestsByName;
    
  NSMutableArray  *filterTests;
  NSMutableArray  *availableTests;

  NSString  *selectedTestName;
  NSString  *testNameToSelect;
  
  // Indicates iff an "okPerformed", "cancelPerformed" or "closePerformed"
  // notification has been fired already.
  BOOL  finalNotificationFired;
  
  // Controls if an empty filter (i.e. a filter without any tests) is allowed.
  BOOL  allowEmptyFilter;
  
  // True iff we currently applying a hack to clear the selection of a browser.
  BOOL  clearBrowserSelectionHack;
}

- (IBAction) applyAction:(id)sender;
- (IBAction) cancelAction:(id)sender;
- (IBAction) okAction:(id)sender;

- (IBAction) addTestToRepository:(id)sender;
- (IBAction) removeTestFromRepository:(id)sender;
- (IBAction) editTestInRepository:(id)sender;

- (IBAction) addTestToFilter:(id)sender;
- (IBAction) removeTestFromFilter:(id)sender;

- (IBAction) filterActionChanged:(id)sender;
- (IBAction) showTestDescriptionChanged:(id)sender;

- (IBAction) handleTestsBrowserClick:(id)sender;

- (id) initWithTestRepository:(FileItemTestRepository*)testRepository;

- (void) removeApplyButton;

- (void) setAllowEmptyFilter: (BOOL) flag;
- (BOOL) allowEmptyFilter;

// Configures the window to represent the given test.
- (void) representFileItemTest:(NSObject <FileItemTest> *)test;

// Creates the test object that represents the current window state.
- (NSObject <FileItemTest> *) createFileItemTest;

@end
