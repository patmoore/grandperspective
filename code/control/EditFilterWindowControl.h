#import <Cocoa/Cocoa.h>


extern NSString  *ClosePerformedEvent;
extern NSString  *ApplyPerformedEvent;
extern NSString  *CancelPerformedEvent;
extern NSString  *OkPerformedEvent;


@class EditFilterRuleWindowControl;
@class NotifyingDictionary;
@class FileItemTestRepository;
@class FileItemFilter;
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

  IBOutlet NSTextView  *testDescriptionView;
  IBOutlet NSDrawer  *testDescriptionDrawer;
  
  IBOutlet NSButton  *applyButton;
  IBOutlet NSButton  *okButton;

  IBOutlet NSButton  *removeTestFromRepositoryButton;
  IBOutlet NSButton  *editTestInRepositoryButton;

  IBOutlet NSButton  *addTestToFilterButton;
  IBOutlet NSButton  *removeTestFromFilterButton;
  IBOutlet NSButton  *removeAllTestsFromFilterButton;
  
  IBOutlet NSTableView  *filterTestsView;
  IBOutlet NSTableView  *availableTestsView;
  
  FileItemTestRepository  *testRepository;
  
  NotifyingDictionary  *repositoryTestsByName;
    
  FileItemFilter  *fileItemFilter;
  NSMutableArray  *availableTests;

  // Non-localized name of currently selected test.
  NSString  *selectedTestName;
  
  // Non-localized name of test to select.
  NSString  *testNameToSelect;
  
  // Indicates iff an "okPerformed", "cancelPerformed" or "closePerformed"
  // notification has been fired already.
  BOOL  finalNotificationFired;
  
  // Controls if an empty filter (i.e. a filter without any tests) is allowed.
  BOOL  allowEmptyFilter;
}

- (IBAction) applyAction:(id)sender;
- (IBAction) cancelAction:(id)sender;
- (IBAction) okAction:(id)sender;

- (IBAction) addTestToRepository:(id)sender;
- (IBAction) removeTestFromRepository:(id)sender;
- (IBAction) editTestInRepository:(id)sender;

- (IBAction) addTestToFilter:(id)sender;
- (IBAction) removeTestFromFilter:(id)sender;
- (IBAction) removeAllTestsFromFilter:(id)sender;

- (IBAction) showTestDescriptionChanged:(id)sender;

- (IBAction) testDoubleClicked:(id)sender;

- (id) initWithTestRepository:(FileItemTestRepository*)testRepository;

- (void) removeApplyButton;

- (void) setAllowEmptyFilter: (BOOL) flag;
- (BOOL) allowEmptyFilter;

/* Configures the window to represent the given filter. It copies the state of
 * the original filter (as far as possible, given that some filter tests may
 * not exist anymore) and leaves the provided filter unchanged.
 */
- (void) representFileItemFilter:(FileItemFilter *)filter;

/* Returns the filter that represents the current window state.
 */
- (FileItemFilter *) fileItemFilter;

@end
