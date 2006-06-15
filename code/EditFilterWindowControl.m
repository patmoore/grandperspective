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
    allTestsByName = 
      [[testRepository testsByNameAsNotifyingDictionary] retain];

    NSNotificationCenter  *nc = [allTestsByName notificationCenter];
    
    [nc addObserver:self selector:@selector(testAddedToRepository:) 
          name:@"objectAdded" object:allTestsByName];
    [nc addObserver:self selector:@selector(testRemovedFromRepository:) 
          name:@"objectRemoved" object:allTestsByName];
    [nc addObserver:self selector:@selector(testUpdatedInRepository:) 
          name:@"objectUpdated" object:allTestsByName];
    [nc addObserver:self selector:@selector(testRenamedInRepository:) 
          name:@"objectRenamed" object:allTestsByName];
            
    filterTests = [[NSMutableArray alloc] initWithCapacity:8];
    availableTests = [[NSMutableArray alloc] 
                 initWithCapacity:[((NSDictionary*)allTestsByName) count] + 8];
                         
    [availableTests
       addObjectsFromArray:[((NSDictionary*)allTestsByName) allKeys]];
  }
  return self;
}

- (void) dealloc {
  NSLog(@"EditFilterWindowControl dealloc");

  [[allTestsByName notificationCenter] removeObserver:self];

  [filterTests release];
  [availableTests release];
  [allTestsByName release];
  
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
          existingTests:((NSDictionary*)allTestsByName)] autorelease];

  int  status = [NSApp runModalForWindow:[ruleWindowControl window]];
  [[ruleWindowControl window] close];
    
  if (status == NSRunStoppedResponse) {
    NSString*  testName = [ruleWindowControl fileItemTestName];

    // The terminationControl should have ensured that this check succeeds.
    NSAssert( [((NSDictionary*)allTestsByName) objectForKey:testName] == nil,
              @"Duplicate name check failed.");

    NSObject <FileItemTest>  *test = [ruleWindowControl createFileItemTest];    

    [testNameToSelect release];
    testNameToSelect = [testName retain];

    [allTestsByName addObject:test forKey:testName];
        
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
    [((NSDictionary*)allTestsByName) objectForKey:oldName];

  [ruleWindowControl representFileItemTest:oldTest];
  [ruleWindowControl setFileItemTestName:oldName];
  
  EditFilterRuleWindowTerminationControl  *terminationControl = 
    [[[EditFilterRuleWindowTerminationControl alloc]
        initWithWindowControl:ruleWindowControl
          existingTests:((NSDictionary*)allTestsByName)
          allowedName:oldName] autorelease];

  int  status = [NSApp runModalForWindow:[ruleWindowControl window]];
  [[ruleWindowControl window] close];
    
  if (status == NSRunStoppedResponse) {
    NSString*  newName = [ruleWindowControl fileItemTestName];

    // The terminationControl should have ensured that this check succeeds.
    NSAssert( [newName isEqualToString:oldName] ||
              [((NSDictionary*)allTestsByName) objectForKey:newName] == nil,
              @"Duplicate name check failed.");
                
    NSObject <FileItemTest>  *newTest = [ruleWindowControl createFileItemTest];
          
    if (! [newName isEqualToString:oldName]) {
      // Handle name change.
      [allTestsByName moveObjectFromKey:oldName toKey:newName];
          
      // Rest of rename handled in response to update notification event.
    }
        
    // Test itself has changed as well.
    [allTestsByName updateObject:newTest forKey:newName];
     
    // Rest of update handled in response to update notification event.
  }
  else {
    NSAssert(status == NSRunAbortedResponse, @"Unexpected status.");
  }
}


- (IBAction) addTestToFilter:(id)sender {
  NSString  *testName = [[availableTestsBrowser selectedCell] stringValue];
  
  if (testName != nil) {
    [filterTests addObject:testName];
    [availableTests removeObject:testName];
    
    [filterTestsBrowser validateVisibleColumns];
    [availableTestsBrowser validateVisibleColumns];
    
    // Select the moved test.
    [filterTestsBrowser selectRow:[filterTests indexOfObject:testName]
                          inColumn:0];

    [self updateWindowState:nil];
  }
}

- (IBAction) removeTestFromFilter:(id)sender {
  NSString  *testName = [[filterTestsBrowser selectedCell] stringValue];
  
  if (testName != nil) {
    [availableTests addObject:testName];
    [filterTests removeObject:testName];

    [filterTestsBrowser validateVisibleColumns];
    [availableTestsBrowser validateVisibleColumns];
    
    // Select the moved test.
    [availableTestsBrowser selectRow:[availableTests indexOfObject:testName]
                             inColumn:0];
    
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
    [cell setStringValue:[availableTests objectAtIndex:row]];
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
    NSObject<FileItemTest>  *subTest = 
      [((NSDictionary*)allTestsByName) objectForKey:testName];
    [subTests addObject:subTest];
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

- (void) testAddedToRepository:(NSNotification*)notification {        
  NSString  *testName = [[notification userInfo] objectForKey:@"key"];

  [availableTests addObject:testName];
  [availableTestsBrowser validateVisibleColumns];
        
  if ([testNameToSelect isEqualToString:testName]) { 
    // Select the newly added test.
    [availableTestsBrowser selectRow:[availableTests indexOfObject:testName]
                             inColumn:0];

    [testNameToSelect release];
    testNameToSelect = nil;
  }
                
  [self updateWindowState:nil];
}


- (void) testRemovedFromRepository:(NSNotification*)notification {
  NSString  *testName = [[notification userInfo] objectForKey:@"key"];

  int  index = [availableTests indexOfObject:testName];
  if (index != NSNotFound) {
    [availableTests removeObjectAtIndex:index];
          
    [availableTestsBrowser validateVisibleColumns];
  }

  index = [filterTests indexOfObject:testName];
  if (index != NSNotFound) {
    [filterTests removeObjectAtIndex:index];
          
    [filterTestsBrowser validateVisibleColumns];
  }

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
  if (index != NSNotFound) {
    NSString  *oldSelectedName = [[availableTestsBrowser selectedCell] title];

    [availableTests replaceObjectAtIndex:index withObject:newTestName];    
    [availableTestsBrowser validateVisibleColumns];
    
    if ([oldSelectedName isEqualToString:oldTestName]) {
      // It was selected, so make sure it still is.
      [availableTestsBrowser selectRow:index inColumn:0];
    }
  }
  
  index = [filterTests indexOfObject:oldTestName];
  if (index != NSNotFound) {
    [filterTests replaceObjectAtIndex:index withObject:newTestName];
          
    [filterTestsBrowser validateVisibleColumns];
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
  if (filterTestsHighlighted) {
    newSelectedTestName = [[filterTestsBrowser selectedCell] title];
  }
  else if (availableTestsHighlighted) {
    newSelectedTestName = [[availableTestsBrowser selectedCell] title];
  }
  
  // If highlighted test changed, update the description text view
  if (newSelectedTestName != selectedTestName) {
    [selectedTestName release];
    selectedTestName = [newSelectedTestName retain];

    if (selectedTestName != nil) {
      NSObject <FileItemTest>  *selectedTest = 
        [((NSDictionary*)allTestsByName) objectForKey:selectedTestName];
      [testDescriptionView setString:[selectedTest description]];
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
    [allTestsByName removeObjectForKey:testName];

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

  if ( ![allowedName isEqualToString:newName] &&
       [allTests objectForKey:newName] != nil) {
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
  
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:
       [NSString stringWithFormat:@"A rule named \"%@\" already exists.",
                   newName]];

    [alert beginSheetModalForWindow:[windowControl window]
             modalDelegate:self 
             didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) 
             contextInfo:nil];
  }
  else {
    NSAssert(!done, @"Already done.");

    [NSApp stopModal];
    done = YES;
  }
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode
          contextInfo:(void *)contextInfo {
  // void
}

@end
