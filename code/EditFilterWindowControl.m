#import "EditFilterWindowControl.h"

#import "filter/StringTest.h"
#import "filter/StringSuffixTest.h"
#import "filter/StringEqualityTest.h"
#import "filter/FileItemTest.h"
#import "filter/ItemNameTest.h"
#import "filter/ItemTypeTest.h"
#import "filter/CompoundAndItemTest.h"

#import "EditFilterRuleWindowControl.h"

@interface EditFilterWindowControl (PrivateMethods)

- (void) updateWindowState:(NSNotification*)notification;

@end

@implementation EditFilterWindowControl

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) init {
  if (self = [super initWithWindowNibName:@"EditFilterWindow" owner:self]) {
    allTestsByName = [[NSMutableDictionary alloc] initWithCapacity:32];
    
    // TEMP: Init with some basic tests.
    // TODO: Should (elsewhere) get this from user defaults eventually.
    NSArray  *imageExtensions = 
      [NSArray arrayWithObjects:@".jpg", @".JPG", @".png", @".PNG", @".gif", 
                                @".GIF", nil];
    NSObject <StringTest>  *imageStringTest = 
      [[[StringSuffixTest alloc] initWithMatchTargets:imageExtensions] 
           autorelease];
    NSObject <FileItemTest>  *imageNameTest =
      [[[ItemNameTest alloc] initWithStringTest:imageStringTest]
           autorelease];
    NSObject <FileItemTest>  *imageTypeTest =
      [[[ItemTypeTest alloc] initWithTestForPlainFile:YES] autorelease];
    NSArray  *imageTests = 
      [NSArray arrayWithObjects:imageNameTest, imageTypeTest, nil];
    NSObject <FileItemTest>  *imageTest = 
      [[[CompoundAndItemTest alloc] initWithSubItemTests:imageTests] 
           autorelease];
    [allTestsByName setObject:imageTest forKey:@"Images"];
    
    NSArray  *musicExtensions = 
      [NSArray arrayWithObjects:@".mp3", @".MP3", @".wav", @".WAV", nil];
    NSObject <StringTest>  *musicStringTest = 
      [[[StringSuffixTest alloc] initWithMatchTargets:musicExtensions]
           autorelease];
    NSObject <FileItemTest>  *musicNameTest =
      [[[ItemNameTest alloc] initWithStringTest:musicStringTest]
           autorelease];
    NSObject <FileItemTest>  *musicTypeTest =
      [[[ItemTypeTest alloc] initWithTestForPlainFile:YES] autorelease];
    NSArray  *musicTests = 
      [NSArray arrayWithObjects:musicNameTest, musicTypeTest, nil];
    NSObject <FileItemTest>  *musicTest = 
      [[[CompoundAndItemTest alloc] initWithSubItemTests:musicTests] 
           autorelease];
    [allTestsByName setObject:musicTest forKey:@"Music"];
    
    NSArray  *versionControlFolders = 
      [NSArray arrayWithObjects:@"CVS", @".svn", nil];
    NSObject <StringTest>  *versionControlStringTest = 
      [[[StringEqualityTest alloc] initWithMatchTargets:versionControlFolders] 
           autorelease];
    NSObject <FileItemTest>  *versionControlNameTest =
      [[[ItemNameTest alloc] initWithStringTest:versionControlStringTest]
           autorelease];
    NSObject <FileItemTest>  *versionControlTypeTest =
      [[[ItemTypeTest alloc] initWithTestForPlainFile:NO] autorelease];
    NSArray  *versionControlTests = 
      [NSArray arrayWithObjects:versionControlNameTest, versionControlTypeTest, 
                                nil];
    NSObject <FileItemTest>  *versionControlTest = 
      [[[CompoundAndItemTest alloc] initWithSubItemTests:versionControlTests]
           autorelease];
    [allTestsByName setObject:versionControlTest forKey:@"Version control"];
                       
    filterTests = [[NSMutableArray alloc] initWithCapacity:8];
    availableTests = [[NSMutableArray alloc] 
                         initWithCapacity:[allTestsByName count] + 8];
    [availableTests addObjectsFromArray:[allTestsByName allKeys]];
  }
  return self;
}

- (void) dealloc {
  [filterTests release];
  [availableTests release];
  [allTestsByName release];
  
  [editFilterRuleWindowControl release];
  
  [super dealloc];
}


- (void) windowDidLoad {
  [filterTestsBrowser setDelegate:self];
  [availableTestsBrowser setDelegate:self];
    
  [[self window] setReleasedWhenClosed:NO];
  
  [filterActionButton removeAllItems];
  [filterActionButton addItemWithTitle:@"Show only"];
  [filterActionButton addItemWithTitle:@"Do not show"];
  
  [self updateWindowState:nil];
}


- (IBAction) cancelFilter:(id)sender {
  [NSApp abortModal];
}

- (IBAction) performFilter:(id)sender {
  [NSApp stopModal];
}


- (IBAction) addTestToRepository:(id)sender {
  if (editFilterRuleWindowControl == nil) {
    // Lazily create it
    editFilterRuleWindowControl = [[EditFilterRuleWindowControl alloc] init];
  }
  else {
    [editFilterRuleWindowControl representFileItemTest:nil];
    [editFilterRuleWindowControl setFileItemTestName:@""];
  }

  while (YES) {
    int  status = 
           [NSApp runModalForWindow:[editFilterRuleWindowControl window]];
    [[editFilterRuleWindowControl window] close];
    
    if (status == NSRunStoppedResponse) {
      NSString*  testName = [editFilterRuleWindowControl fileItemTestName];

      if ([allTestsByName objectForKey:testName] != nil) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:
          [NSString stringWithFormat:@"A rule named \"%@\" already exists.",
                      testName]];

        [alert runModal];
      }
      else {
        NSObject <FileItemTest>  *test = 
          [editFilterRuleWindowControl createFileItemTest];    
        [allTestsByName setObject:test forKey:testName];

        [availableTests addObject:testName];
        [availableTestsBrowser validateVisibleColumns];
        
        // Select the newly added test.
        [availableTestsBrowser selectRow:[availableTests indexOfObject:testName]
                                 inColumn:0];
        
        [self updateWindowState:nil];

        break;
      }
    }
    else {
      NSAssert(status == NSRunAbortedResponse, @"Unexpected status.");
      break;
    }
  }
}


- (IBAction) removeTestFromRepository:(id)sender {
  NSString  *testName = [[availableTestsBrowser selectedCell] stringValue];
  
  NSAlert *alert = [[[NSAlert alloc] init] autorelease];

  [alert addButtonWithTitle:@"OK"];
  [alert addButtonWithTitle:@"Cancel"];
  [alert setMessageText:
           [NSString stringWithFormat:@"Remove the rule named \"%@\"?",
              testName]];

  if ([alert runModal] == NSAlertFirstButtonReturn) {
    // Delete confirmed.
    [allTestsByName removeObjectForKey:testName];
    [availableTests removeObject:testName];
          
    [availableTestsBrowser validateVisibleColumns];
    
    [self updateWindowState:nil];
  }
}


- (IBAction) editTestInRepository:(id)sender {
  if (editFilterRuleWindowControl == nil) {
    // Lazily create it
    editFilterRuleWindowControl = [[EditFilterRuleWindowControl alloc] init];
    // Force loading of the window.
    [editFilterRuleWindowControl window];
  }

  NSString  *oldName = [[availableTestsBrowser selectedCell] stringValue];
  NSObject <FileItemTest>  *oldTest = [allTestsByName objectForKey:oldName];

  [editFilterRuleWindowControl representFileItemTest:oldTest];
  [editFilterRuleWindowControl setFileItemTestName:oldName];

  while (YES) {
    int  status = 
           [NSApp runModalForWindow:[editFilterRuleWindowControl window]];
    [[editFilterRuleWindowControl window] close];
    
    if (status == NSRunStoppedResponse) {
      NSString*  newName = [editFilterRuleWindowControl fileItemTestName];

      if (! [newName isEqualToString:oldName] &&
          [allTestsByName objectForKey:newName] != nil) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:
          [NSString stringWithFormat:@"A rule named \"%@\" already exists.",
                      newName]];

        [alert runModal];
      }
      else {
        NSObject <FileItemTest>  *newTest = 
          [editFilterRuleWindowControl createFileItemTest];
          
        if ([newName isEqualToString:oldName]) {
          // Name did not change, so only replace test
          [allTestsByName setObject:newTest forKey:newName];
          
          // Invalidate "cached" test description text (even though the name
          // is the same, the test itself may have changed).
          [selectedTestName release];
          selectedTestName = nil;
        }
        else {
          // Name changed, so test under old name, and add new one.
          [allTestsByName removeObjectForKey:oldName];
          [availableTests removeObject:oldName];
          
          [allTestsByName setObject:newTest forKey:newName];
          [availableTests addObject:newName];
          
          [availableTestsBrowser validateVisibleColumns];
        }
  
        [self updateWindowState:nil];
        
        break;
      }
    }
    else {
      NSAssert(status == NSRunAbortedResponse, @"Unexpected status.");
      break;
    }
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

@end

@implementation EditFilterWindowControl (PrivateMethods)

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
        [allTestsByName objectForKey:selectedTestName];
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

  [performFilterButton setEnabled: ([filterTests count] > 0)];
}

@end
