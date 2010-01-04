#import "EditFilterWindowControl.h"

#import "ControlConstants.h"
#import "NotifyingDictionary.h"

#import "FileItemTest.h"

#import "FilterTestRepository.h"
#import "Filter.h"
#import "NamedFilter.h"
#import "FilterTest.h"
#import "MutableFilterTestRef.h"

#import "NameValidator.h"
#import "ModalityTerminator.h"

#import "EditFilterTestWindowControl.h"


NSString  *NameColumn = @"name";
NSString  *MatchColumn = @"match";


/* Performs a validity check on the name of filter tests (before the window is 
 * closed using the OK button).
 */
@interface FilterTestNameValidator : NSObject <NameValidator> {
  NSDictionary  *allTests;
  NSString  *allowedName;
}

- (id) initWithExistingTests:(NSDictionary *)allTests;
- (id) initWithExistingTests:(NSDictionary *)allTests 
         allowedName:(NSString *)name;

@end // @interface FilterTestNameValidator


@interface EditFilterWindowControl (PrivateMethods)

- (NSArray *)availableTests;

// Returns the non-localized name of the selected available test (if any).
- (NSString *)selectedAvailableTestName;

// Returns the selected filter test (if any).
- (MutableFilterTestRef *)selectedFilterTest;

- (int) indexOfTestInFilterNamed:(NSString *)name;

/* Helper method for creating FilterTests to be added to the filter. It sets
 * the inverted and canToggleInverted flags correctly.
 */
- (MutableFilterTestRef *)filterTestForTestNamed:(NSString *)name; 

- (void) testAddedToRepository:(NSNotification *)notification;
- (void) testRemovedFromRepository:(NSNotification *)notification;
- (void) testUpdatedInRepository:(NSNotification *)notification;
- (void) testRenamedInRepository:(NSNotification *)notification;

- (void) updateWindowState:(NSNotification *)notification;

- (void) confirmTestRemovalAlertDidEnd:(NSAlert *)alert 
           returnCode:(int) returnCode contextInfo:(void *)contextInfo;

- (void) alertDidEnd:(NSAlert *)alert returnCode:(int) returnCode
           contextInfo:(void *)contextInfo;

@end // @interface EditFilterWindowControl (PrivateMethods)


@implementation EditFilterWindowControl

- (id) init {
  return [self initWithTestRepository:
                 [FilterTestRepository defaultFilterTestRepository]];
}

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) initWithTestRepository:(FilterTestRepository *)testRepositoryVal {
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

    filterName = nil;
    filterTests = [[NSMutableArray alloc] initWithCapacity: 8];
    
    availableTests = [[NSMutableArray alloc] 
      initWithCapacity: [((NSDictionary *)repositoryTestsByName) count] + 8];
    [availableTests
       addObjectsFromArray: [((NSDictionary *)repositoryTestsByName) allKeys]];
    [availableTests sortUsingSelector: @selector(compare:)];

    nameValidator = nil;
       
    allowEmptyFilter = NO; // Default
  }
  return self;
}

- (void) dealloc {
  [testRepository release];

  [[repositoryTestsByName notificationCenter] removeObserver:self];

  [repositoryTestsByName release];
  
  [filterName release];
  [filterTests release];
  [availableTests release];
  
  [nameValidator release];
  
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


- (void) setAllowEmptyFilter:(BOOL) flag {
  allowEmptyFilter = flag;
}

- (BOOL) allowEmptyFilter {
  return allowEmptyFilter;
}


- (void)windowDidBecomeKey:(NSNotification *)notification {
  finalNotificationFired = NO;

  if ([filterTestsView selectedRow] != -1) {
    [[self window] makeFirstResponder: filterTestsView];
  }
  else {
    [[self window] makeFirstResponder: availableTestsView];
  }
}

- (void) windowWillClose:(NSNotification *)notification {
  if (! finalNotificationFired ) {
    // The window is closing while no "okPerformed" or "cancelPerformed" has
    // been fired yet. This means that the user is closing the window using
    // the window's red close button.
    
    [[NSNotificationCenter defaultCenter] 
        postNotificationName: ClosePerformedEvent object: self];
  }
}

- (IBAction) applyAction:(id) sender {
  [[NSNotificationCenter defaultCenter] 
      postNotificationName: ApplyPerformedEvent object: self];
}

- (IBAction) cancelAction:(id) sender {
  NSAssert( !finalNotificationFired, @"Final notification already fired." );

  finalNotificationFired = YES;
  [[NSNotificationCenter defaultCenter] 
      postNotificationName: CancelPerformedEvent object: self];
}

- (IBAction) okAction:(id) sender {
  NSAssert( !finalNotificationFired, @"Final notification already fired." );

  // Check if the name of the test is okay.
  NSString  *errorMsg = [nameValidator checkNameIsValid: [self filterName]];
      
  if (errorMsg != nil) {
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
  
    [alert addButtonWithTitle: OK_BUTTON_TITLE];
    [alert setMessageText: errorMsg];

    [alert beginSheetModalForWindow: [self window]
             modalDelegate: self 
             didEndSelector: @selector(alertDidEnd:returnCode:contextInfo:) 
             contextInfo: nil];
  }
  else {
    finalNotificationFired = YES;
    [[NSNotificationCenter defaultCenter] 
        postNotificationName: OkPerformedEvent object: self];
  }
}


- (IBAction) removeTestFromRepository:(id) sender {
  NSString  *testName = [self selectedAvailableTestName];
  
  NSAlert  *alert = [[[NSAlert alloc] init] autorelease];

  NSString  *fmt = NSLocalizedString( @"Remove the test named \"%@\"?",
                                      @"Alert message" );
  NSString  *infoMsg = 
    ([testRepository applicationProvidedTestForName: testName] != nil) ?
      NSLocalizedString(
        @"The test will be replaced by the default test with this name.",
        @"Alert informative text" ) :
      NSLocalizedString( 
        @"The test will be irrevocably removed from the test repository.",
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


- (IBAction) addTestToRepository:(id) sender {
  EditFilterTestWindowControl  *editTestWindowControl = 
    [EditFilterTestWindowControl defaultInstance];
  
  // Ensure window is loaded before configuring its contents
  NSWindow  *editTestWindow = [editTestWindowControl window]; 

  FilterTestNameValidator  *testNameValidator = 
    [[[FilterTestNameValidator alloc]
        initWithExistingTests: ((NSDictionary *)repositoryTestsByName)] 
          autorelease];
  
  [editTestWindowControl setNameValidator: testNameValidator];
  [editTestWindowControl representFilterTest: nil];

  [ModalityTerminator modalityTerminatorForEventSource: editTestWindowControl];
  int  status = [NSApp runModalForWindow: editTestWindow];
  [editTestWindow close];

  if (status == NSRunStoppedResponse) {
    FilterTest  *filterTest = [editTestWindowControl createFilterTest];
    
    if (filterTest != nil) {
      NSString  *name = [filterTest name];

      // The nameValidator should have ensured that this check succeeds.
      NSAssert( 
        [((NSDictionary *)repositoryTestsByName) objectForKey: name] == nil,
        @"Duplicate name check failed.");

      [testNameToSelect release];
      testNameToSelect = [name retain];

      [repositoryTestsByName addObject: [filterTest fileItemTest] forKey: name];
        
      // Rest of addition handled in response to notification event.
    }
  }
  else {
    NSAssert(status == NSRunAbortedResponse, @"Unexpected status.");
  }
}


- (IBAction) editTestInRepository:(id) sender {
  EditFilterTestWindowControl  *editTestWindowControl = 
    [EditFilterTestWindowControl defaultInstance];

  NSString  *oldName = [self selectedAvailableTestName];
  FileItemTest  *oldTest = 
    [((NSDictionary *)repositoryTestsByName) objectForKey: oldName];

  // Ensure window is loaded before configuring its contents
  NSWindow  *editTestWindow = [editTestWindowControl window];

  [editTestWindowControl representFilterTest: 
     [FilterTest filterTestWithName: oldName fileItemTest: oldTest]];

  if ([testRepository applicationProvidedTestForName: oldName] != nil) {
    // The test's name equals that of an application provided test. Show the
    // localized version of the name (which implicitly prevents the name from
    // being changed).
  
    NSBundle  *mainBundle = [NSBundle mainBundle];
    NSString  *localizedName = 
      [mainBundle localizedStringForKey: oldName value: nil table: @"Names"];
      
    [editTestWindowControl setVisibleName: localizedName];
  }
  
  FilterTestNameValidator  *testNameValidator = 
    [[[FilterTestNameValidator alloc]
        initWithExistingTests: ((NSDictionary *)repositoryTestsByName)
        allowedName: oldName] autorelease];
  
  [editTestWindowControl setNameValidator: testNameValidator];
  
  [ModalityTerminator modalityTerminatorForEventSource: editTestWindowControl];
  int  status = [NSApp runModalForWindow: editTestWindow];
  [editTestWindow close];
    
  if (status == NSRunStoppedResponse) {
    FilterTest  *newFilterTest = [editTestWindowControl createFilterTest];
    
    if (newFilterTest != nil) {
      NSString  *newName = [newFilterTest name];

      // The terminationControl should have ensured that this check succeeds.
      NSAssert( 
        [newName isEqualToString: oldName] ||
        [((NSDictionary *)repositoryTestsByName) objectForKey: newName] == nil,
        @"Duplicate name check failed.");

      if (! [newName isEqualToString: oldName]) {
        // Handle name change.
        [repositoryTestsByName moveObjectFromKey: oldName toKey: newName];
          
        // Rest of rename handled in response to update notification event.
      }
        
      // Test itself has changed as well.
      [repositoryTestsByName updateObject: [newFilterTest fileItemTest] 
                               forKey: newName];

      // Rest of update handled in response to update notification event.
    }
  }
  else {
    NSAssert(status == NSRunAbortedResponse, @"Unexpected status.");
  }
}


- (IBAction) addTestToFilter:(id) sender {
  NSString  *testName = [self selectedAvailableTestName];
  
  if (testName != nil) {
    FilterTestRef  *filterTest = [self filterTestForTestNamed: testName];
    NSAssert(filterTest != nil, @"Test not found in repository.");
        
    [filterTests addObject: filterTest];
    
    [filterTestsView reloadData];
    [availableTestsView reloadData];
    
    // Select the newly added test.
    [filterTestsView selectRow: [filterTests indexOfObject: filterTest]
                       byExtendingSelection: NO];
    [[self window] makeFirstResponder: filterTestsView];

    [self updateWindowState: nil];
  }
}

- (IBAction) removeTestFromFilter:(id) sender {
  int  index = [filterTestsView selectedRow];
  
  if (index >= 0) {
    NSString  *testName = [[filterTests objectAtIndex: index] name];
    
    [filterTests removeObjectAtIndex: index];

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

- (IBAction) removeAllTestsFromFilter:(id) sender {
  [filterTests removeAllObjects];
  
  [filterTestsView reloadData];
  [availableTestsView reloadData];

  [self updateWindowState: nil];
}

- (IBAction) showTestDescriptionChanged:(id) sender {
  NSButton  *button = sender;
  if ([button state] == NSOffState) {
    [testDescriptionDrawer close];
  }
  else if ([button state] == NSOnState) {
    [testDescriptionDrawer open];
  }
}

- (IBAction) testDoubleClicked:(id) sender {
  MutableFilterTestRef  *filterTest = [self selectedFilterTest];
  if (filterTest != nil && [filterTest canToggleInverted]) {
    [filterTest toggleInverted];
    [filterTestsView reloadData];
  }
}


//----------------------------------------------------------------------------
// NSTableSource

- (int) numberOfRowsInTableView:(NSTableView *)tableView {
  if (tableView == filterTestsView) {
    return [filterTests count];
  }
  else if (tableView == availableTestsView) {
    return [availableTests count];
  }
  else {
    NSAssert(NO, @"Unexpected sender.");
  }
}

- (id) tableView:(NSTableView *)tableView 
         objectValueForTableColumn:(NSTableColumn *)column row:(int) row {
  NSBundle  *mainBundle = [NSBundle mainBundle];
  
  if (tableView == filterTestsView) {
    FilterTestRef  *filterTest = [filterTests objectAtIndex: row];

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

- (void) tableView:(NSTableView *)tableView willDisplayCell:(id) cell 
           forTableColumn:(NSTableColumn *)column row:(int) row {
  NSBundle  *mainBundle = [NSBundle mainBundle];
  
  if (tableView == availableTestsView) {
    NSString  *name = [availableTests objectAtIndex: row];

    [cell setEnabled: [self indexOfTestInFilterNamed: name] < 0];
  }
}

- (void) tableViewSelectionDidChange:(NSNotification *)notification {
  [self updateWindowState: nil];
}


- (NSString *)filterName {
  if ([filterNameField isEnabled]) {
    // No fixed "visible" name was set, so get the name from the text field.
    return [filterNameField stringValue];
  }
  else {
    // The test name field was showing the test's visible name. Return its
    // original name.
    return filterName;
  }
}


- (void) setNameValidator:(NSObject<NameValidator> *)validator {
  if (validator != nameValidator) {
    [nameValidator release];
    nameValidator = [validator retain];
  }
}


- (void) representEmptyFilter {
  NamedFilter  *emptyFilter = [NamedFilter emptyFilterWithName: @""];
  [self representNamedFilter: emptyFilter];
}


// Configures the window to represent the given filter.
- (void) representNamedFilter:(NamedFilter *)namedFilter {
  NSAssert(namedFilter != nil, @"Filter should not be nil.");
  
  Filter  *filter = [namedFilter filter];
  [filterTests removeAllObjects];
  
  int  i = 0;
  int  max = [filter numFilterTests];
  while (i < max) {
    FilterTestRef  *orgFilterTest = [filter filterTestAtIndex: i];
    NSString  *name = [orgFilterTest name];
    
    MutableFilterTestRef  *newFilterTest = [self filterTestForTestNamed: name];
    if (newFilterTest != nil) {
      if ( [newFilterTest canToggleInverted] &&
           [newFilterTest isInverted] != [orgFilterTest isInverted] ) {
        [newFilterTest toggleInverted];
      }
    
      [filterTests addObject: newFilterTest];
    }
    else {
      NSLog(@"Test \"%@\" does not exist anymore in repository.", name);

      // Simply omit it.
    }

    i++;
  }
  
  [filterTestsView reloadData];
  [availableTestsView reloadData];
  
  if (filterName != [namedFilter name]) {
    [filterName release];
    filterName = [[namedFilter name] retain];
  }
  [filterNameField setStringValue: filterName];
  [filterNameField setEnabled: YES];
  
  [self updateWindowState: nil];
}

// Returns the filter that represents the current window state.
- (NamedFilter *)createNamedFilter {
  Filter  *filter = [Filter filterWithFilterTests: filterTests];
  return [NamedFilter namedFilter: filter name: [self filterName]];
}


- (void) setVisibleName:(NSString *)name {
  [filterNameField setStringValue: name];
  [filterNameField setEnabled: NO];
}

@end // @implementation EditFilterWindowControl


@implementation EditFilterWindowControl (PrivateMethods)

- (NSArray *)availableTests {
  return availableTests;
}

// Returns the non-localized name of the selected available test (if any).
- (NSString *)selectedAvailableTestName {
  int  index = [availableTestsView selectedRow];
  
  return (index < 0) ? nil : [availableTests objectAtIndex: index];
}

// Returns the selected filter test (if any).
- (MutableFilterTestRef *)selectedFilterTest {
  int  index = [filterTestsView selectedRow];
  
  return (index < 0) ? nil : [filterTests objectAtIndex: index];
}

- (int) indexOfTestInFilterNamed:(NSString *)name {
  int  i = [filterTests count];

  while (--i >= 0) {
    if ([[[filterTests objectAtIndex: i] name] isEqualToString: name]) {
      return i;
    }
  }
  
  return -1;
}


- (MutableFilterTestRef *)filterTestForTestNamed:(NSString *)name {
  FileItemTest  *test = 
    [((NSDictionary *)repositoryTestsByName) objectForKey: name];

  if (test == nil) {
    return nil;
  }

  MutableFilterTestRef  *filterTest = 
    [[MutableFilterTestRef alloc] initWithName: name];

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


- (void) testAddedToRepository:(NSNotification *)notification { 
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


- (void) testRemovedFromRepository:(NSNotification *)notification {
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


- (void) testUpdatedInRepository:(NSNotification *)notification {
  NSString  *testName = [[notification userInfo] objectForKey: @"key"];

  if ([selectedTestName isEqualToString: testName]) {
    // Invalidate the selected test description text (as it may have changed).
    [selectedTestName release];
    selectedTestName = nil;
  }
  
  [self updateWindowState: nil];
}


- (void) testRenamedInRepository:(NSNotification *)notification {
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


- (void) updateWindowState:(NSNotification *)notification {
  FilterTestRef  *selectedFilterTest = [self selectedFilterTest];
  NSString  *selectedAvailableTestName = [self selectedAvailableTestName];

  if (selectedAvailableTestName != nil) {
    int  index = [self indexOfTestInFilterNamed: selectedAvailableTestName];
      
    if (index >= 0) {
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
  
  FileItemTest  *newSelectedTest = 
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

  BOOL  nonEmptyFilter = ([filterTests count] > 0);

  [removeAllTestsFromFilterButton setEnabled: nonEmptyFilter];
  
  [applyButton setEnabled: (nonEmptyFilter || allowEmptyFilter)];
  [okButton setEnabled: (nonEmptyFilter || allowEmptyFilter)];
}


- (void) confirmTestRemovalAlertDidEnd:(NSAlert *)alert 
          returnCode:(int) returnCode contextInfo:(void *)testName {
  if (returnCode == NSAlertFirstButtonReturn) {
    // Delete confirmed.
    
    FileItemTest  *defaultTest = 
      [testRepository applicationProvidedTestForName: testName];
    
    if (defaultTest == nil) {
      [repositoryTestsByName removeObjectForKey: testName];
    }
    else {
      // Replace it by the application-provided test with the same name
      // (this would happen anyway when the application is restarted).
      [repositoryTestsByName updateObject: defaultTest forKey: testName];
    }

    // Rest of delete handled in response to notification event.
  }
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(int) returnCode
           contextInfo:(void *)contextInfo {
  // void
}

@end // @implementation EditFilterWindowControl (PrivateMethods)


@implementation FilterTestNameValidator

// Overrides designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithExistingTests: instead.");
}

- (id) initWithExistingTests:(NSDictionary *)allTestsVal {
  return [self initWithExistingTests: allTestsVal allowedName: nil];
}

- (id) initWithExistingTests:(NSDictionary *)allTestsVal
         allowedName:(NSString *)name {
  if (self = [super init]) {
    allTests = [allTestsVal retain];
    allowedName = [name retain];    
  }
  
  return self;
}

- (void) dealloc {
  [allTests release];
  [allowedName release];

  [super dealloc];
}


- (NSString *)checkNameIsValid:(NSString *)name {
  NSString*  errorText = nil;

  if ([name isEqualToString:@""]) {
    return NSLocalizedString( @"The test must have a name.",
                              @"Alert message" );
  }
  else if ( ![allowedName isEqualToString: name] &&
            [allTests objectForKey: name] != nil) {
    NSString  *fmt = NSLocalizedString( @"A test named \"%@\" already exists.",
                                        @"Alert message" );
    return [NSString stringWithFormat: fmt, name];
  }
  
  // All OK
  return nil;
}

@end // @implementation FilterTestNameValidator

