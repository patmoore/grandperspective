#import "EditFilterWindowControl.h"

#import "ControlConstants.h"
#import "NotifyingDictionary.h"

#import "FileItemTest.h"
#import "FileItemTestRepository.h"
#import "FileItemFilter.h"
#import "FilterTest.h"

#import "EditFilterRuleWindowControl.h"


NSString  *ClosePerformedEvent = @"closePerformed";
NSString  *ApplyPerformedEvent = @"applyPerformed";
NSString  *CancelPerformedEvent = @"cancelPerformed";
NSString  *OkPerformedEvent = @"okPerformed";

NSString  *NameColumn = @"name";
NSString  *MatchColumn = @"match";


// Handles closing of the "Edit Filter Rule Window", including a validity
// check before the window is closed.
@interface EditFilterRuleWindowTerminationControl : NSObject {
  EditFilterRuleWindowControl  *windowControl;
  NSDictionary  *allTests;
  NSString  *allowedName;
  BOOL  done;
}

- (id) initWithWindowControl:(EditFilterRuleWindowControl*)windowControl 
         existingTests:(NSDictionary*)allTests;
- (id) initWithWindowControl:(EditFilterRuleWindowControl*)windowControl 
         existingTests:(NSDictionary*)allTests 
         allowedName:(NSString*)name;

- (void) windowClosing:(NSNotification*)notification;
- (void) cancelAction:(NSNotification*)notification;
- (void) okAction:(NSNotification*)notification;

- (void) alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode 
           contextInfo:(void *)contextInfo;

@end // EditFilterRuleWindowTerminationControl


@interface EditFilterWindowControl (PrivateMethods)

- (NSArray *) availableTests;

// Returns the non-localized name of the selected available test (if any).
- (NSString *) selectedAvailableTestName;

// Returns the selected filter test (if any).
- (FilterTest *) selectedFilterTest;

/* Helper method for creating FilterTests to be added to the filter. It sets
 * the inverted and canToggleInverted flags correctly.
 */
- (FilterTest *) filterTestForTestNamed:(NSString *)name; 

- (void) testAddedToRepository:(NSNotification*)notification;
- (void) testRemovedFromRepository:(NSNotification*)notification;
- (void) testUpdatedInRepository:(NSNotification*)notification;
- (void) testRenamedInRepository:(NSNotification*)notification;

- (void) updateWindowState:(NSNotification*)notification;

- (void) confirmTestRemovalAlertDidEnd:(NSAlert *)alert 
           returnCode:(int)returnCode contextInfo:(void *)contextInfo;

@end // EditFilterWindowControl (PrivateMethods)


@implementation EditFilterWindowControl

- (id) init {
  return [self initWithTestRepository:
                 [FileItemTestRepository defaultFileItemTestRepository]];
}

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) initWithTestRepository: (FileItemTestRepository *)testRepositoryVal {
  if (self = [super initWithWindowNibName:@"EditFilterWindow" owner:self]) {
    testRepository = [testRepositoryVal retain];
    repositoryTestsByName = 
      [[testRepository testsByNameAsNotifyingDictionary] retain];

    NSNotificationCenter  *nc = [repositoryTestsByName notificationCenter];
    
    [nc addObserver:self selector: @selector(testAddedToRepository:) 
          name: ObjectAddedEvent object: repositoryTestsByName];
    [nc addObserver:self selector: @selector(testRemovedFromRepository:) 
          name: ObjectRemovedEvent object: repositoryTestsByName];
    [nc addObserver:self selector: @selector(testUpdatedInRepository:) 
          name: ObjectUpdatedEvent object: repositoryTestsByName];
    [nc addObserver:self selector: @selector(testRenamedInRepository:) 
          name: ObjectRenamedEvent object: repositoryTestsByName];

    fileItemFilter = [[FileItemFilter alloc] init];

    availableTests = [[NSMutableArray alloc] 
      initWithCapacity: [((NSDictionary *)repositoryTestsByName) count] + 8];
    [availableTests
       addObjectsFromArray: [((NSDictionary *)repositoryTestsByName) allKeys]];
    [availableTests sortUsingSelector: @selector(compare:)];
       
    allowEmptyFilter = NO; // Default
  }
  return self;
}

- (void) dealloc {
  [testRepository release];

  [[repositoryTestsByName notificationCenter] removeObserver:self];

  [repositoryTestsByName release];
  
  [fileItemFilter release];
  [availableTests release];
  
  [selectedTestName release];
  [testNameToSelect release];
  
  [super dealloc];
}


- (void) windowDidLoad {
  [filterTestsView setDelegate: self];
  [filterTestsView setDataSource: self];
  
  [filterTestsView setTarget: self];
  [filterTestsView setDoubleAction: @selector(testDoubleClicked:)];
  
  [availableTestsView setDelegate: self];
  [availableTestsView setDataSource: self];
  
  [[[filterTestsView tableColumnWithIdentifier: MatchColumn] dataCell]
       setImageAlignment: NSImageAlignRight];
    
  [self updateWindowState:nil];
}


- (void) removeApplyButton {
  if (applyButton != nil) {
    [applyButton removeFromSuperviewWithoutNeedingDisplay];
    // [applyButton release];
    applyButton = nil;
  }
}


- (void) setAllowEmptyFilter: (BOOL) flag {
  allowEmptyFilter = flag;
}

- (BOOL) allowEmptyFilter {
  return allowEmptyFilter;
}


- (void)windowDidBecomeKey:(NSNotification *)aNotification {
  finalNotificationFired = NO;

  if ([filterTestsView selectedRow] != -1) {
    [[self window] makeFirstResponder: filterTestsView];
  }
  else {
    [[self window] makeFirstResponder: availableTestsView];
  }
}

- (void) windowWillClose:(NSNotification*)notification {
  if (! finalNotificationFired ) {
    // The window is closing while no "okPerformed" or "cancelPerformed" has
    // been fired yet. This means that the user is closing the window using
    // the window's red close button.
    
    [[NSNotificationCenter defaultCenter] 
        postNotificationName: ClosePerformedEvent object: self];
  }
}

- (IBAction) applyAction:(id)sender {
  [[NSNotificationCenter defaultCenter] 
      postNotificationName: ApplyPerformedEvent object: self];
}

- (IBAction) cancelAction:(id)sender {
  NSAssert( !finalNotificationFired, @"Final notification already fired." );

  finalNotificationFired = YES;
  [[NSNotificationCenter defaultCenter] 
      postNotificationName: CancelPerformedEvent object: self];
}

- (IBAction) okAction:(id)sender {
  NSAssert( !finalNotificationFired, @"Final notification already fired." );

  finalNotificationFired = YES;
  [[NSNotificationCenter defaultCenter] 
      postNotificationName: OkPerformedEvent object: self];
}


- (IBAction) removeTestFromRepository: (id)sender {
  NSString  *testName = [self selectedAvailableTestName];
  
  NSAlert  *alert = [[[NSAlert alloc] init] autorelease];

  NSString  *fmt = NSLocalizedString( @"Remove the rule named \"%@\"?",
                                      @"Alert message" );
  NSString  *infoMsg = 
    ([testRepository applicationProvidedTestForName: testName] != nil) ?
      NSLocalizedString(
        @"The rule will be replaced by the default rule with this name.",
        @"Alert informative text" ) :
      NSLocalizedString( 
        @"The rule will be irrevocably removed from the rule repository.",
        @"Alert informative text" );

  NSBundle  *mainBundle = [NSBundle mainBundle];
  NSString  *localizedName = 
    [mainBundle localizedStringForKey: testName value: nil table: @"Names"];
  
  [alert addButtonWithTitle: REMOVE_BUTTON_TITLE];
  [alert addButtonWithTitle: CANCEL_BUTTON_TITLE];
  [alert setMessageText: [NSString stringWithFormat: fmt, localizedName]];
  [alert setInformativeText: infoMsg];

  [alert beginSheetModalForWindow: [self window] modalDelegate: self
           didEndSelector: @selector(confirmTestRemovalAlertDidEnd: 
                                       returnCode:contextInfo:) 
           contextInfo: testName];
}


- (IBAction) addTestToRepository:(id)sender {
  EditFilterRuleWindowControl  *ruleWindowControl = 
    [EditFilterRuleWindowControl defaultInstance];
  
  // Ensure window is loaded before configuring its contents
  NSWindow  *ruleWindow = [ruleWindowControl window];  

  EditFilterRuleWindowTerminationControl  *terminationControl = 
    [[[EditFilterRuleWindowTerminationControl alloc]
        initWithWindowControl:ruleWindowControl
          existingTests:((NSDictionary*)repositoryTestsByName)] autorelease];

  [ruleWindowControl representFileItemTest:nil];

  int  status = [NSApp runModalForWindow:ruleWindow];
  [ruleWindow close];

  if (status == NSRunStoppedResponse) {
    NSObject <FileItemTest>  *test = [ruleWindowControl createFileItemTest];
    
    if (test != nil) {
      NSString*  testName = [test name];

      // The terminationControl should have ensured that this check succeeds.
      NSAssert( 
        [((NSDictionary*)repositoryTestsByName) objectForKey:testName] == nil,
        @"Duplicate name check failed.");

      [testNameToSelect release];
      testNameToSelect = [testName retain];

      [repositoryTestsByName addObject:test forKey:testName];
        
      // Rest of addition handled in response to notification event.
    }
  }
  else {
    NSAssert(status == NSRunAbortedResponse, @"Unexpected status.");
  }
}


- (IBAction) editTestInRepository:(id)sender {
  EditFilterRuleWindowControl  *ruleWindowControl = 
    [EditFilterRuleWindowControl defaultInstance];

  NSString  *oldName = [self selectedAvailableTestName];
  NSObject <FileItemTest>  *oldTest = 
    [((NSDictionary*)repositoryTestsByName) objectForKey: oldName];

  // Ensure window is loaded before configuring its contents
  NSWindow  *ruleWindow = [ruleWindowControl window];

  [ruleWindowControl representFileItemTest: oldTest];

  if ([testRepository applicationProvidedTestForName: oldName] != nil) {
    // The rule's name equals that of an application provided test. Show the
    // localized version of the name (which implicitly prevents the name from
    // being changed).
  
    NSBundle  *mainBundle = [NSBundle mainBundle];
    NSString  *localizedName = 
      [mainBundle localizedStringForKey: oldName value: nil table: @"Names"];
      
    [ruleWindowControl setVisibleName: localizedName];
  }
  
  EditFilterRuleWindowTerminationControl  *terminationControl = 
    [[[EditFilterRuleWindowTerminationControl alloc]
        initWithWindowControl: ruleWindowControl
          existingTests: ((NSDictionary*)repositoryTestsByName)
          allowedName: oldName] autorelease];

  int  status = [NSApp runModalForWindow: ruleWindow];
  [ruleWindow close];
    
  if (status == NSRunStoppedResponse) {
    NSObject <FileItemTest>  *newTest = [ruleWindowControl createFileItemTest];
    
    if (newTest != nil) {
      NSString  *newName = [newTest name];

      // The terminationControl should have ensured that this check succeeds.
      NSAssert( 
        [newName isEqualToString: oldName] ||
        [((NSDictionary*)repositoryTestsByName) objectForKey: newName] == nil,
        @"Duplicate name check failed.");

      if (! [newName isEqualToString: oldName]) {
        // Handle name change.
        [repositoryTestsByName moveObjectFromKey: oldName toKey: newName];
          
        // Rest of rename handled in response to update notification event.
      }
        
      // Test itself has changed as well.
      [repositoryTestsByName updateObject: newTest forKey: newName];

      // Rest of update handled in response to update notification event.
    }
  }
  else {
    NSAssert(status == NSRunAbortedResponse, @"Unexpected status.");
  }
}


- (IBAction) addTestToFilter:(id)sender {
  NSString  *testName = [self selectedAvailableTestName];
  
  if (testName != nil) {
    FilterTest  *filterTest = [self filterTestForTestNamed: testName];
    NSAssert(filterTest != nil, @"Test not found in repository.");
        
    [fileItemFilter addFilterTest: filterTest];
    
    [filterTestsView reloadData];
    [availableTestsView reloadData];
    
    // Select the newly added test.
    [filterTestsView selectRow: [fileItemFilter indexOfFilterTest: filterTest]
                       byExtendingSelection: NO];
    [[self window] makeFirstResponder: filterTestsView];

    [self updateWindowState: nil];
  }
}

- (IBAction) removeTestFromFilter:(id)sender {
  int  index = [filterTestsView selectedRow];
  
  if (index >= 0) {
    NSString  *testName = [[fileItemFilter filterTestAtIndex: index] name];
    
    [fileItemFilter removeFilterTestAtIndex: index];

    [filterTestsView reloadData];
    [availableTestsView reloadData];
    
    // Select the test in the repository (if it still exists there)
    int  index = [availableTests indexOfObject: testName];
    if (index != NSNotFound) {
      [availableTestsView selectRow: index byExtendingSelection: NO];
      [[self window] makeFirstResponder: availableTestsView];
    }
    
    [self updateWindowState: nil];
  }
}

- (IBAction) removeAllTestsFromFilter:(id)sender {
  [fileItemFilter removeAllFilterTests];
  
  [filterTestsView reloadData];
  [availableTestsView reloadData];

  [self updateWindowState: nil];
}

- (IBAction) showTestDescriptionChanged:(id)sender {
  NSButton  *button = sender;
  if ([button state] == NSOffState) {
    [testDescriptionDrawer close];
  }
  else if ([button state] == NSOnState) {
    [testDescriptionDrawer open];
  }
}

- (IBAction) testDoubleClicked:(id)sender {
  FilterTest  *filterTest = [self selectedFilterTest];
  if (filterTest != nil && [filterTest canToggleInverted]) {
    [filterTest toggleInverted];
    [filterTestsView reloadData];
  }
}


//----------------------------------------------------------------------------
// NSTableSource

- (int) numberOfRowsInTableView: (NSTableView *)tableView {
  if (tableView == filterTestsView) {
    return [fileItemFilter numFilterTests];
  }
  else if (tableView == availableTestsView) {
    return [availableTests count];
  }
  else {
    NSAssert(NO, @"Unexpected sender.");
  }
}

- (id) tableView: (NSTableView *)tableView 
         objectValueForTableColumn: (NSTableColumn *)column row: (int) row {
  NSBundle  *mainBundle = [NSBundle mainBundle];
  
  if (tableView == filterTestsView) {
    FilterTest  *filterTest = [fileItemFilter filterTestAtIndex: row];

    if ([[column identifier] isEqualToString: NameColumn]) {
      return [mainBundle localizedStringForKey: [filterTest name] value: nil 
                           table: @"Names"];
    }
    else if ([[column identifier] isEqualToString: MatchColumn]) {
      return [NSImage imageNamed: 
                        ([filterTest isInverted] ? @"Cross" : @"Checkmark")];
    }
    else {
      NSAssert(NO, @"Unknown column.");
    }
  }
  else if (tableView == availableTestsView) {
    NSString  *name = [availableTests objectAtIndex: row]; 
    return [mainBundle localizedStringForKey: name value: nil table: @"Names"];
  }
}


//-----------------------------------------------------------------------------
// Delegate methods for NSTableView

- (void) tableView:(NSTableView *)tableView willDisplayCell: (id) cell 
           forTableColumn: (NSTableColumn *)column row: (int) row {
  NSBundle  *mainBundle = [NSBundle mainBundle];
  
  if (tableView == availableTestsView) {
    NSString  *name = [availableTests objectAtIndex: row]; 

    [cell setEnabled: ([fileItemFilter filterTestWithName: name] == nil)];
  }
}

- (void) tableViewSelectionDidChange: (NSNotification *) notification {
  [self updateWindowState: nil];
}


// Configures the window to represent the given filter.
- (void) representFileItemFilter:(FileItemFilter *)filter {
  [fileItemFilter removeAllFilterTests];
  
  int  i = 0;
  int  max = [filter numFilterTests];
  while (i < max) {
    FilterTest  *orgFilterTest = [filter filterTestAtIndex: i];
    NSString  *name = [orgFilterTest name];
    
    FilterTest  *newFilterTest = [self filterTestForTestNamed: name];
    if (newFilterTest != nil) {
      if ( [newFilterTest canToggleInverted] &&
           [newFilterTest isInverted] != [orgFilterTest isInverted] ) {
        [newFilterTest toggleInverted];
      }
    
      [fileItemFilter addFilterTest: newFilterTest];
    }
    else {
      NSLog(@"Test \"%@\" does not exist anymore in repository.", name);

      // Simply omit it.
    }

    i++;
  }
  
  [filterTestsView reloadData];
  [availableTestsView reloadData];
  
  [self updateWindowState: nil];
}

// Returns the filter that represents the current window state.
- (FileItemFilter *) fileItemFilter {
  // Return a copy
  return [[[FileItemFilter alloc] initWithFileItemFilter: fileItemFilter]
              autorelease];
}

@end // @implementation EditFilterWindowControl


@implementation EditFilterWindowControl (PrivateMethods)

- (NSArray *) availableTests {
  return availableTests;
}

// Returns the non-localized name of the selected available test (if any).
- (NSString *) selectedAvailableTestName {
  int  index = [availableTestsView selectedRow];
  
  return (index < 0) ? nil : [availableTests objectAtIndex: index];
}

// Returns the selected filter test (if any).
- (FilterTest *) selectedFilterTest {
  int  index = [filterTestsView selectedRow];
  
  return (index < 0) ? nil : [fileItemFilter filterTestAtIndex: index];
}


- (FilterTest *) filterTestForTestNamed:(NSString *)name {
  NSObject <FileItemTest>  *test = 
      [((NSDictionary *)repositoryTestsByName) objectForKey: name];

  if (test == nil) {
    return nil;
  }

  FilterTest  *filterTest = [FilterTest filterTestWithName: name];

  if ([test appliesToDirectories]) {
    // Fix "inverted" state of the filter test.     
    
    if (! [filterTest isInverted]) {
      [filterTest setCanToggleInverted: YES]; // Not needed, but no harm.
      [filterTest toggleInverted];
    }
    [filterTest setCanToggleInverted: NO];
  }
  
  return filterTest;
}


- (void) testAddedToRepository:(NSNotification*)notification {        
  NSString  *testName = [[notification userInfo] objectForKey:@"key"];
  NSString  *selectedName = [self selectedAvailableTestName];

  [availableTests addObject: testName];
  // Ensure that the tests remain sorted.
  [availableTests sortUsingSelector: @selector(compare:)];
  [availableTestsView reloadData];
        
  if ([testNameToSelect isEqualToString: testName]) { 
    // Select the newly added test.
    [availableTestsView selectRow: [availableTests indexOfObject: testName]
                          byExtendingSelection: NO];
    [[self window] makeFirstResponder: availableTestsView];

    [testNameToSelect release];
    testNameToSelect = nil;
  }
  else if (selectedName != nil) {
    // Make sure that the same test is still selected.
    [availableTestsView selectRow: [availableTests indexOfObject: selectedName]
                          byExtendingSelection: NO];
  }
                
  [self updateWindowState:nil];
}


- (void) testRemovedFromRepository:(NSNotification*)notification {
  NSString  *testName = [[notification userInfo] objectForKey:@"key"];
  NSString  *selectedName = [self selectedAvailableTestName];

  int  index = [availableTests indexOfObject:testName];
  NSAssert(index != NSNotFound, @"Test not found in available tests.");

  [availableTests removeObjectAtIndex:index];
  [availableTestsView reloadData];
  
  if ([testName isEqualToString: selectedName]) {
    // The removed test was selected. Clear the selection.
    [availableTestsView deselectAll: self];
  }
  else if (selectedName != nil) {
    // Make sure that the same test is still selected. 
    [availableTestsView selectRow: [availableTests indexOfObject: selectedName]
                          byExtendingSelection: NO];
  }

  [self updateWindowState:nil];
}


- (void) testUpdatedInRepository:(NSNotification*)notification {
  NSString  *testName = [[notification userInfo] objectForKey: @"key"];

  if ([selectedTestName isEqualToString: testName]) {
    // Invalidate the selected test description text (as it may have changed).
    [selectedTestName release];
    selectedTestName = nil;
  }
  
  [self updateWindowState: nil];
}


- (void) testRenamedInRepository: (NSNotification *)notification {
  NSString  *oldTestName = [[notification userInfo] objectForKey: @"oldkey"];
  NSString  *newTestName = [[notification userInfo] objectForKey: @"newkey"];

  int  index = [availableTests indexOfObject: oldTestName];
  NSAssert(index != NSNotFound, @"Test not found in available tests.");

  NSString  *selectedName = [self selectedAvailableTestName];

  [availableTests replaceObjectAtIndex: index withObject: newTestName];
  // Ensure that the tests remain sorted.
  [availableTests sortUsingSelector: @selector(compare:)];
  [availableTestsView reloadData];
    
  if ([selectedName isEqualToString: oldTestName]) {
    // It was selected, so make sure it still is.
    selectedName = newTestName;
  }
  if (selectedName != nil) {
    // Make sure that the same test is still selected. 
    [availableTestsView selectRow: [availableTests indexOfObject: selectedName]
                          byExtendingSelection: NO];
  }
}


- (void) updateWindowState: (NSNotification *)notification {
  FilterTest  *selectedFilterTest = [self selectedFilterTest];
  NSString  *selectedAvailableTestName = [self selectedAvailableTestName];

  if (selectedAvailableTestName != nil) {
    FilterTest  *filterTest = 
      [fileItemFilter filterTestWithName: selectedAvailableTestName];
      
    if (filterTest != nil) {
      // The window is in an anomalous situation: a test is selected in the
      // available tests view, even though the test is used in the filter.
      //
      // This anomalous situation can occur as follows:
      // 1. Create a mask, and press OK (to apply it and close the window).
      // 2. Edit the mask. Remove one of the tests from the filter, but now
      //    press Cancel (so that the mask remains unchanged, yet the window
      //    closes)
      // 3. Edit the mask again. Now the focus will still be on the test in the
      //    available test window that had been moved in Step 2. However, as 
      //    this change was undone by cancelling the mask, the test is actually
      //    not available and thus disabled.
    
      // Select the disabled test in the other view.      
      int  index = [fileItemFilter indexOfFilterTest: filterTest];
      [filterTestsView selectRow: index byExtendingSelection: NO];

      [availableTestsView deselectAll: nil];
      selectedAvailableTestName = nil;

      [[self window] makeFirstResponder: filterTestsView];
    }
  }

  BOOL  filterTestsHighlighted = 
          ( [[self window] firstResponder] == filterTestsView );
  BOOL  availableTestsHighlighted = 
          ( [[self window] firstResponder] == availableTestsView );

  // Find out which test (if any) is currently highlighted.
  NSString  *newSelectedTestName = nil;

  if (filterTestsHighlighted) {
    newSelectedTestName = [selectedFilterTest name];
  }
  else if (availableTestsHighlighted) {
    newSelectedTestName = selectedAvailableTestName;
  }
  
  NSObject <FileItemTest>  *newSelectedTest = 
    [((NSDictionary *)repositoryTestsByName) 
                        objectForKey: newSelectedTestName];

  // If highlighted test changed, update the description text view
  if (newSelectedTestName != selectedTestName) {  
    [selectedTestName release];
    selectedTestName = [newSelectedTestName retain];

    if (newSelectedTest != nil) {
      [testDescriptionView setString: [newSelectedTest description]];
    }
    else {
      [testDescriptionView setString: @""];
    }
  }
  
  // Update enabled status of buttons with context-dependent actions.
  BOOL  availableTestHighlighted = 
          ( selectedAvailableTestName != nil && availableTestsHighlighted );

  [editTestInRepositoryButton setEnabled: availableTestHighlighted];
  // Cannot remove an application-provided tess (it would automatically
  // re-appear anyway).
  [removeTestFromRepositoryButton setEnabled: 
    (availableTestHighlighted && 
      (newSelectedTest != [testRepository applicationProvidedTestForName: 
                                            selectedAvailableTestName])) ];

  [addTestToFilterButton setEnabled: availableTestHighlighted];
  [removeTestFromFilterButton setEnabled: 
    ( selectedFilterTest != nil && filterTestsHighlighted )];

  BOOL  nonEmptyFilter = ([fileItemFilter numFilterTests] > 0);

  [removeAllTestsFromFilterButton setEnabled: nonEmptyFilter];
  
  [applyButton setEnabled: (nonEmptyFilter || allowEmptyFilter)];
  [okButton setEnabled: (nonEmptyFilter || allowEmptyFilter)];
}


- (void) confirmTestRemovalAlertDidEnd:(NSAlert *)alert 
          returnCode:(int)returnCode contextInfo:(void *)testName {
  if (returnCode == NSAlertFirstButtonReturn) {
    // Delete confirmed.
    
    NSObject <FileItemTest>  *defaultTest = 
      [testRepository applicationProvidedTestForName: testName];
    
    if (defaultTest == nil) {
      [repositoryTestsByName removeObjectForKey:testName];
    }
    else {
      // Replace it by the application-provided test with the same name
      // (this would happen anyway when the application is restarted).
      [repositoryTestsByName updateObject: defaultTest forKey: testName];
    }

    // Rest of delete handled in response to notification event.
  }
}

@end


@implementation EditFilterRuleWindowTerminationControl

// Overrides designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithWindowControl:existingTests: instead.");
}

- (id) initWithWindowControl:(EditFilterRuleWindowControl*)windowControlVal
         existingTests:(NSDictionary*)allTestsVal {
  return [self initWithWindowControl:windowControlVal
                 existingTests:allTestsVal allowedName:nil];
}

- (id) initWithWindowControl:(EditFilterRuleWindowControl*)windowControlVal 
         existingTests:(NSDictionary*)allTestsVal
         allowedName:(NSString*)name {
  if (self = [super init]) {
    windowControl = [windowControlVal retain];
    allTests = [allTestsVal retain];
    allowedName = [name retain];
    
    done = NO;
    
    NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self selector: @selector(cancelAction:)
          name: CancelPerformedEvent object:windowControl];
    [nc addObserver: self selector: @selector(okAction:)
          name: OkPerformedEvent object:windowControl];
    [nc addObserver: self selector: @selector(windowClosing:)
          name: NSWindowWillCloseNotification object: [windowControl window]];
  }
  
  return self;
}

- (void) dealloc {
  [windowControl release];
  [allTests release];
  [allowedName release];

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [super dealloc];
}


- (void) windowClosing:(NSNotification*)notification {
  if (!done) {
    [NSApp abortModal];
    done = YES;
  }
}

- (void) cancelAction:(NSNotification*)notification {
  NSAssert(!done, @"Already done.");

  [NSApp abortModal];
  done = YES;
}

- (void) okAction:(NSNotification*)notification {
  NSString*  newName = [windowControl fileItemTestName];
  NSString*  errorText = nil;

  if ([newName isEqualToString:@""]) {
    errorText = NSLocalizedString( @"The rule must have a name.",
                                   @"Alert message" );
  }
  else if ( ![allowedName isEqualToString:newName] &&
            [allTests objectForKey:newName] != nil) {
    NSString  *fmt = NSLocalizedString( @"A rule named \"%@\" already exists.",
                                        @"Alert message" );
            
    errorText = [NSString stringWithFormat: fmt, newName];
  }
 
  if (errorText != nil) {
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
  
    [alert addButtonWithTitle: OK_BUTTON_TITLE];
    [alert setMessageText: errorText];

    [alert beginSheetModalForWindow:[windowControl window]
             modalDelegate:self 
             didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) 
             contextInfo:nil];
  }
  else {
    NSAssert(!done, @"Already done.");

    done = YES;
    [NSApp stopModal];
  }
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode
          contextInfo:(void *)contextInfo {
  // void
}

@end // @implementation EditFilterRuleWindowTerminationControl

