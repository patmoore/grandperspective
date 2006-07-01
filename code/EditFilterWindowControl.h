#import <Cocoa/Cocoa.h>

@class EditFilterRuleWindowControl;
@class NotifyingDictionary;
@class FileItemTestRepository;
@protocol FileItemTest;

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

// Configures the window to represent the given test.
- (void) representFileItemTest:(NSObject <FileItemTest> *)test;

// Creates the test object that represents the current window state.
- (NSObject <FileItemTest> *) createFileItemTest;

@end
