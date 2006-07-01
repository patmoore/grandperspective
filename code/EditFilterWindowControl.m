#import "EditFilterWindowControl.h"

#import "util/NotifyingDictionary.h"

#import "filter/FileItemTestRepository.h"
#import "filter/CompoundOrItemTest.h"
#import "filter/NotItemTest.h"

#import "EditFilterRuleWindowControl.h"


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

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode 
          contextInfo:(void *)contextInfo;

@end


@interface EditFilterWindowControl (PrivateMethods)

- (NSArray *) availableTests;
- (NSArray *) filterTests;
- (NSPopUpButton *) filterActionButton;

- (void) testAddedToRepository:(NSNotification*)notification;
- (void) testRemovedFromRepository:(NSNotification*)notification;
- (void) testUpdatedInRepository:(NSNotification*)notification;
- (void) testRenamedInRepository:(NSNotification*)notification;

- (void) updateWindowState:(NSNotification*)notification;

- (void) confirmTestRemovalAlertDidEnd:(NSAlert *)alert 
          returnCode:(int)returnCode contextInfo:(void *)contextInfo;

@end

@implementation EditFilterWindowControl

- (id) init {
  return [self initWithTestRepository:
                 [FileItemTestRepository defaultFileItemTestRepository]];
}

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) initWithTestRepository:(FileItemTestRepository*)testRepository {
  if (self = [super initWithWindowNibName:@"EditFilterWindow" owner:self]) {
    repositoryTestsByName = 
      [[testRepository testsByNameAsNotifyingDictionary] retain];

    NSNotificationCenter  *nc = [repositoryTestsByName notificationCenter];
    
    [nc addObserver:self selector:@selector(testAddedToRepository:) 
          name:@"objectAdded" object:repositoryTestsByName];
    [nc addObserver:self selector:@selector(testRemovedFromRepository:) 
          name:@"objectRemoved" object:repositoryTestsByName];
    [nc addObserver:self selector:@selector(testUpdatedInRepository:) 
          name:@"objectUpdated" object:repositoryTestsByName];
    [nc addObserver:self selector:@selector(testRenamedInRepository:) 
          name:@"objectRenamed" object:repositoryTestsByName];
          
    filterTestsByName = [[NSMutableDictionary alloc] initWithCapacity:8];
            
    filterTests = [[NSMutableArray alloc] initWithCapacity:8];
    availableTests = [[NSMutableArray alloc] 
      initWithCapacity:[((NSDictionary*)repositoryTestsByName) count] + 8];
                         
    [availableTests
       addObjectsFromArray:[((NSDictionary*)repositoryTestsByName) allKeys]];
  }
  return self;
}

- (void) dealloc {
  NSLog(@"EditFilterWindowControl dealloc");

  [[repositoryTestsByName notificationCenter] removeObserver:self];

  [repositoryTestsByName release];
  [filterTestsByName release];
  
  [filterTests release];
  [availableTests release];
  
  [selectedTestName release];
  [testNameToSelect release];
  
  [super dealloc];
}


- (void) windowDidLoad {
  [filterTestsBrowser setDelegate:self];
  [availableTestsBrowser setDelegate:self];
  
  [filterActionButton removeAllItems];
  [filterActionButton addItemWithTitle:@"Show only"];
  [filterActionButton addItemWithTitle:@"Do not show"];
  
  [self updateWindowState:nil];
}


- (void) mirrorStateOfEditFilterWindowControl:(EditFilterWindowControl*)other {
  [availableTests setArray:[other availableTests]];
  [availableTestsBrowser validateVisibleColumns];
  
  [filterTests setArray:[other filterTests]];
  [filterTestsBrowser validateVisibleColumns];
  
  [filterActionButton selectItemAtIndex:
                        [[other filterActionButton] indexOfSelectedItem]];
}


- (void) removeApplyButton {
  if (applyButton != nil) {
    [applyButton removeFromSuperviewWithoutNeedingDisplay];
    // [applyButton release];
    applyButton = nil;
  }
}


- (IBAction) applyAction:(id)sender {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"applyPerformed"
                                          object:self];
}

- (IBAction) cancelAction:(id)sender {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"cancelPerformed"
                                          object:self];
}

- (IBAction) okAction:(id)sender {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"okPerformed"
                                          object:self];
}


- (IBAction) removeTestFromRepository:(id)sender {
  NSString  *testName = [[availableTestsBrowser selectedCell] stringValue];
  
  NSAlert *alert = [[[NSAlert alloc] init] autorelease];

  [alert addButtonWithTitle:@"OK"];
  [alert addButtonWithTitle:@"Cancel"];
  [alert setMessageText:
           [NSString stringWithFormat:@"Remove the rule named \"%@\"?",
              testName]];
  [alert setInformativeText:
           @"The rule will be irrevocably removed from the rule repository."];

  [alert beginSheetModalForWindow:[self window] modalDelegate:self
           didEndSelector:@selector(confirmTestRemovalAlertDidEnd: 
                                      returnCode:contextInfo:) 
           contextInfo:testName];
}


- (IBAction) addTestToRepository:(id)sender {
  EditFilterRuleWindowControl  *ruleWindowControl = 
    [EditFilterRuleWindowControl defaultInstance];

  [ruleWindowControl representFileItemTest:nil];
  [ruleWindowControl setFileItemTestName:@""];
  
  EditFilterRuleWindowTerminationControl  *terminationControl = 
    [[[EditFilterRuleWindowTerminationControl alloc]
        initWithWindowControl:ruleWindowControl
          existingTests:((NSDictionary*)repositoryTestsByName)] autorelease];

  int  status = [NSApp runModalForWindow:[ruleWindowControl window]];
  [[ruleWindowControl window] close];
    
  if (status == NSRunStoppedResponse) {
    NSString*  testName = [ruleWindowControl fileItemTestName];

    // The terminationControl should have ensured that this check succeeds.
    NSAssert( 
      [((NSDictionary*)repositoryTestsByName) objectForKey:testName] == nil,
      @"Duplicate name check failed.");

    NSObject <FileItemTest>  *test = [ruleWindowControl createFileItemTest];    

    [testNameToSelect release];
    testNameToSelect = [testName retain];

    [repositoryTestsByName addObject:test forKey:testName];
        
    // Rest of addition handled in response to notification event.
  }
  else {
    NSAssert(status == NSRunAbortedResponse, @"Unexpected status.");
  }
}


- (IBAction) editTestInRepository:(id)sender {
  EditFilterRuleWindowControl  *ruleWindowControl = 
    [EditFilterRuleWindowControl defaultInstance];

  NSString  *oldName = [[availableTestsBrowser selectedCell] stringValue];
  NSObject <FileItemTest>  *oldTest = 
    [((NSDictionary*)repositoryTestsByName) objectForKey:oldName];

  // Ensure window is loaded before configuring its contents
  NSWindow  *ruleWindowControlWindow = [ruleWindowControl window];

  [ruleWindowControl representFileItemTest:oldTest];
  [ruleWindowControl setFileItemTestName:oldName];
  
  EditFilterRuleWindowTerminationControl  *terminationControl = 
    [[[EditFilterRuleWindowTerminationControl alloc]
        initWithWindowControl:ruleWindowControl
          existingTests:((NSDictionary*)repositoryTestsByName)
          allowedName:oldName] autorelease];

  int  status = [NSApp runModalForWindow:ruleWindowControlWindow];
  [ruleWindowControlWindow close];
    
  if (status == NSRunStoppedResponse) {
    NSString*  newName = [ruleWindowControl fileItemTestName];

    // The terminationControl should have ensured that this check succeeds.
    NSAssert( 
      [newName isEqualToString:oldName] ||
      [((NSDictionary*)repositoryTestsByName) objectForKey:newName] == nil,
      @"Duplicate name check failed.");
                
    NSObject <FileItemTest>  *newTest = [ruleWindowControl createFileItemTest];
          
    if (! [newName isEqualToString:oldName]) {
      // Handle name change.
      [repositoryTestsByName moveObjectFromKey:oldName toKey:newName];
          
      // Rest of rename handled in response to update notification event.
    }
        
    // Test itself has changed as well.
    [repositoryTestsByName updateObject:newTest forKey:newName];
     
    // Rest of update handled in response to update notification event.
  }
  else {
    NSAssert(status == NSRunAbortedResponse, @"Unexpected status.");
  }
}


- (IBAction) addTestToFilter:(id)sender {
  NSString  *testName = [[availableTestsBrowser selectedCell] stringValue];
  
  if (testName != nil) {
    NSObject  *test = 
      [((NSDictionary*)repositoryTestsByName) objectForKey:testName];
    NSAssert(test != nil, @"Test not found in repository.");

    [filterTests addObject:testName];
    [filterTestsByName setObject:test forKey:testName];
    
    [filterTestsBrowser validateVisibleColumns];
    [availableTestsBrowser validateVisibleColumns];
    
    // Select the newly added test.
    [filterTestsBrowser selectRow:[filterTests indexOfObject:testName]
                          inColumn:0];
    [[self window] makeFirstResponder:filterTestsBrowser];

    [self updateWindowState:nil];
  }
}

- (IBAction) removeTestFromFilter:(id)sender {
  NSString  *testName = [[filterTestsBrowser selectedCell] stringValue];
  
  if (testName != nil) {
    [filterTests removeObject:testName];
    [filterTestsByName removeObjectForKey:testName];

    [filterTestsBrowser validateVisibleColumns];
    [availableTestsBrowser validateVisibleColumns];
    
    // Select the test in the repository (if it still exists there)
    int  index = [availableTests indexOfObject:testName];
    if (index != NSNotFound) {
      [availableTestsBrowser selectRow:index inColumn:0];
      [[self window] makeFirstResponder:availableTestsBrowser];
    }
    
    [self updateWindowState:nil];
  }
}

- (IBAction) filterActionChanged:(id)sender {
  // void
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

// Delegate methods for NSBrowser
- (BOOL)browser:(NSBrowser*)sender isColumnValid:(int)column {
  NSAssert(column==0, @"Invalid column.");
  
  // When "validateVisibleColumns" is called, the visible column (just one)
  // can always be assumed to invalid.
  return NO;
}

- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column {
  NSLog(@"browser:numberOfRowsInColumn");
  NSAssert(column==0, @"Invalid column.");
  
  if (sender == filterTestsBrowser) {
    return [filterTests count];
  }
  else if (sender == availableTestsBrowser) {
    return [availableTests count];
  }
  else {
    NSAssert(NO, @"Unexpected sender.");
  }
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row 
         column:(int)column {
  NSAssert(column==0, @"Invalid column.");
  
  if (sender == filterTestsBrowser) {
    [cell setStringValue:[filterTests objectAtIndex:row]];
  }
  else if (sender == availableTestsBrowser) {
    NSString  *testName = [availableTests objectAtIndex:row]; 
    [cell setStringValue:testName];
    [cell setEnabled: ([filterTestsByName objectForKey:testName] == nil)];
  }
  else {
    NSAssert(NO, @"Unexpected sender.");
  }

  // Common for both.
  [cell setLeaf:YES];
}


// HACK: Not sure why this works, but it does. The two delegate methods of
// receiving selection events are only called in exceptional cases.
- (IBAction)handleTestsBrowserClick:(id)sender {
  [self updateWindowState:nil];
}


// Creates the test object that represents the current window state.
- (NSObject <FileItemTest> *) createFileItemTest {
  if ([filterTests count] == 0) {
    // Return "nil" to indicate that there is no filtering.
    return nil;
  }
  
  NSMutableArray  *subTests = 
    [NSMutableArray arrayWithCapacity:[filterTests count]];
  NSEnumerator  *testNameEnum = [filterTests objectEnumerator];
  NSString  *testName;
  while (testName = [testNameEnum nextObject]) {
    [subTests addObject: [filterTestsByName objectForKey:testName] ];
  }
  
  NSObject <FileItemTest>  *orTest = 
    [[[CompoundOrItemTest alloc] initWithSubItemTests:subTests] autorelease];
    
  if ([filterActionButton indexOfSelectedItem] == 0) {
    // Show only
    return orTest;
  }
  else {
    // Don't show
    return [[[NotItemTest alloc] initWithSubItemTest:orTest] autorelease];
  }
}

@end


@implementation EditFilterWindowControl (PrivateMethods)

- (NSArray *) availableTests {
  return availableTests;
}

- (NSArray *) filterTests {
  return filterTests;
}

- (NSPopUpButton *) filterActionButton {
  return filterActionButton;
}


- (void) testAddedToRepository:(NSNotification*)notification {        
  NSString  *testName = [[notification userInfo] objectForKey:@"key"];

  [availableTests addObject:testName];
  [availableTestsBrowser validateVisibleColumns];
        
  if ([testNameToSelect isEqualToString:testName]) { 
    // Select the newly added test.
    [availableTestsBrowser selectRow:[availableTests indexOfObject:testName]
                             inColumn:0];
    [[self window] makeFirstResponder:availableTestsBrowser];

    [testNameToSelect release];
    testNameToSelect = nil;
  }
                
  [self updateWindowState:nil];
}


- (void) testRemovedFromRepository:(NSNotification*)notification {
  NSString  *testName = [[notification userInfo] objectForKey:@"key"];

  int  index = [availableTests indexOfObject:testName];
  NSAssert(index != NSNotFound, @"Test not found in available tests.");

  [availableTests removeObjectAtIndex:index];
  [availableTestsBrowser validateVisibleColumns];

  [self updateWindowState:nil];
}


- (void) testUpdatedInRepository:(NSNotification*)notification {
  NSString  *testName = [[notification userInfo] objectForKey:@"key"];

  if ([selectedTestName isEqualToString:testName]) {
    // Invalidate the selected test description text (as it may have changed).
    [selectedTestName release];
    selectedTestName = nil;
  }
  
  [self updateWindowState:nil];
}


- (void) testRenamedInRepository:(NSNotification*)notification {
  NSString  *oldTestName = [[notification userInfo] objectForKey:@"oldkey"];
  NSString  *newTestName = [[notification userInfo] objectForKey:@"newkey"];

  int  index = [availableTests indexOfObject:oldTestName];
  NSAssert(index != NSNotFound, @"Test not found in available tests.");

  NSString  *oldSelectedName = [[availableTestsBrowser selectedCell] title];

  [availableTests replaceObjectAtIndex:index withObject:newTestName];    
  [availableTestsBrowser validateVisibleColumns];
    
  if ([oldSelectedName isEqualToString:oldTestName]) {
    // It was selected, so make sure it still is.
    [availableTestsBrowser selectRow:index inColumn:0];
  }
}


- (void) updateWindowState:(NSNotification*)notification {

  BOOL  filterTestsHighlighted = 
          ( [[self window] firstResponder]
            == [filterTestsBrowser matrixInColumn:0] );
  BOOL  availableTestsHighlighted = 
          ( [[self window] firstResponder]
            == [availableTestsBrowser matrixInColumn:0] );

  // Find out which test (if any) is currently highlighted.
  NSString  *newSelectedTestName = nil;
  NSObject <FileItemTest>  *newSelectedTest = nil;
  if (filterTestsHighlighted) {
    newSelectedTestName = [[filterTestsBrowser selectedCell] title];
    newSelectedTest = [filterTestsByName objectForKey:newSelectedTestName];

    NSAssert(newSelectedTest != nil, @"Test not in dictionary.");
  }
  else if (availableTestsHighlighted) {
    newSelectedTestName = [[availableTestsBrowser selectedCell] title];
    newSelectedTest =
      [((NSDictionary*)repositoryTestsByName) objectForKey:newSelectedTestName];
  }
  
  // If highlighted test changed, update the description text view
  if (newSelectedTestName != selectedTestName) {
    [selectedTestName release];
    selectedTestName = [newSelectedTestName retain];

    if (newSelectedTest != nil) {
      [testDescriptionView setString:[newSelectedTest description]];
    }
    else {
      [testDescriptionView setString:@""];
    }
  }
  
  // Update enabled status of buttons with context-dependent actions.
  BOOL  availableTestHighlighted = 
          ( ([availableTestsBrowser selectedCell] != nil) && 
            availableTestsHighlighted );

  [removeTestFromRepositoryButton setEnabled:availableTestHighlighted];
  [editTestInRepositoryButton setEnabled:availableTestHighlighted];
  [addTestToFilterButton setEnabled:availableTestHighlighted];

  [removeTestFromFilterButton setEnabled: 
    ( ([filterTestsBrowser selectedCell] != nil) &&
      filterTestsHighlighted )];

  // [performFilterButton setEnabled: ([filterTests count] > 0)];
}


- (void) confirmTestRemovalAlertDidEnd:(NSAlert *)alert 
          returnCode:(int)returnCode contextInfo:(void *)testName {
  if (returnCode == NSAlertFirstButtonReturn) {
    // Delete confirmed.
    [repositoryTestsByName removeObjectForKey:testName];

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
    [nc addObserver:self selector:@selector(cancelAction:)
          name:@"cancelPerformed" object:windowControl];
    [nc addObserver:self selector:@selector(okAction:)
          name:@"okPerformed" object:windowControl];
    [nc addObserver:self selector:@selector(windowClosing:)
          name:@"NSWindowWillCloseNotification" object:[windowControl window]];
  }
  
  return self;
}

- (void) dealloc {
  NSLog(@"EditFilterRuleWindowTerminationControl dealloc");
  
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
    errorText = @"The rule must have a name.";
  }
  else if ( ![allowedName isEqualToString:newName] &&
            [allTests objectForKey:newName] != nil) {
    errorText = 
      [NSString stringWithFormat:@"A rule named \"%@\" already exists.",
                  newName];
  }
 
  if (errorText != nil) {
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
  
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:errorText];

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

@end
