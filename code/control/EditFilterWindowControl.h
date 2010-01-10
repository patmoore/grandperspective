#import <Cocoa/Cocoa.h>

@class EditFilterTestWindowControl;
@class FilterTestRepository;
@class FilterTestEditor;
@class NamedFilter;
@protocol NameValidator;

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

  IBOutlet NSTextField  *filterNameField;

  IBOutlet NSTextView  *testDescriptionView;
  IBOutlet NSDrawer  *testDescriptionDrawer;

  IBOutlet NSButton  *okButton;

  IBOutlet NSButton  *removeTestFromRepositoryButton;
  IBOutlet NSButton  *editTestInRepositoryButton;

  IBOutlet NSButton  *addTestToFilterButton;
  IBOutlet NSButton  *removeTestFromFilterButton;
  IBOutlet NSButton  *removeAllTestsFromFilterButton;
  
  IBOutlet NSTableView  *filterTestsView;
  IBOutlet NSTableView  *availableTestsView;
  
  FilterTestRepository  *testRepository;
  FilterTestEditor  *testEditor;
  
  NSObject <NameValidator>  *nameValidator;
  // Indicates if the name if known to be invalid (by the user).
  BOOL  invalidName;

  // Non-localized name of the filter.
  NSString  *filterName;

  NSMutableArray  *filterTests;
  NSMutableArray  *availableTests;

  // Locale-independent name of currently selected test.
  NSString  *selectedTestName;
  
  // Indicates iff an "okPerformed", "cancelPerformed" or "closePerformed"
  // notification has been fired already.
  BOOL  finalNotificationFired;
  
  // Controls if an empty filter (i.e. a filter without any tests) is allowed.
  BOOL  allowEmptyFilter;
}

- (IBAction) cancelAction:(id) sender;
- (IBAction) okAction:(id) sender;

- (IBAction) filterNameChanged:(id) sender;

- (IBAction) addTestToRepository:(id) sender;
- (IBAction) removeTestFromRepository:(id) sender;
- (IBAction) editTestInRepository:(id) sender;

- (IBAction) addTestToFilter:(id) sender;
- (IBAction) removeTestFromFilter:(id) sender;
- (IBAction) removeAllTestsFromFilter:(id) sender;

- (IBAction) showTestDescriptionChanged:(id) sender;

- (IBAction) testDoubleClicked:(id) sender;

- (id) initWithTestRepository:(FilterTestRepository *)testRepository;

- (void) setAllowEmptyFilter:(BOOL) flag;
- (BOOL) allowEmptyFilter;

/* Returns the name of the filter, given the current window state.
 */
- (NSString *)filterName;

- (void) setNameValidator:(NSObject<NameValidator> *)validator;

/* Configures the window to represent an empty filter.
 */
- (void) representEmptyFilter;

/* Configures the window to represent the given filter. It copies the state of
 * the original filter (as far as possible, given that some filter tests may
 * not exist anymore) and leaves the provided filter unchanged.
 */
- (void) representNamedFilter:(NamedFilter *)filterVal;

/* Returns a filter that represents the current window state.
 */
- (NamedFilter *)createNamedFilter;

/* Sets the name of the filter as it is shown in the window. This may be
 * different from the actual name  (in particular, the visible name may be
 * localized). Once a visible name is set, it cannot be changed.
 */
- (void) setVisibleName:(NSString *)name;

@end
