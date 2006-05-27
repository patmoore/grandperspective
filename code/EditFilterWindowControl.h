#import <Cocoa/Cocoa.h>


@interface EditFilterWindowControl : NSWindowController {

  IBOutlet NSPopUpButton  *filterActionButton;

  IBOutlet NSTextView  *testDescriptionView;

  //IBOutlet NSButton  *cancelFilterButton;
  IBOutlet NSButton  *performFilterButton;

  //IBOutlet NSButton  *addTestToRepositoryButton;
  IBOutlet NSButton  *removeTestFromRepositoryButton;
  IBOutlet NSButton  *editTestInRepositoryButton;

  IBOutlet NSButton  *addTestToFilterButton;
  IBOutlet NSButton  *removeTestFromFilterButton;
  
  IBOutlet NSBrowser  *filterTestBrowser;
  IBOutlet NSBrowser  *repositoryTestBrowser;

}

- (IBAction) cancelFilter:(id)sender;
- (IBAction) performFilter:(id)sender;

- (IBAction) addTestToRepository:(id)sender;
- (IBAction) removeTestFromRepository:(id)sender;
- (IBAction) editTestInRepository:(id)sender;

- (IBAction) addTestToFilter:(id)sender;
- (IBAction) removeTestFromFilter:(id)sender;

- (IBAction) filterActionChanged:(id)sender;
- (IBAction) showTestDescriptionChanged:(id)sender;

@end
