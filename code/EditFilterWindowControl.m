#import "EditFilterWindowControl.h"

#import "filter/StringTest.h"
#import "filter/StringSuffixTest.h"
#import "filter/StringEqualityTest.h"
#import "filter/FileItemTest.h"
#import "filter/FileNameTest.h"
#import "filter/DirectoryNameTest.h"

@interface EditFilterWindowControl (PrivateMethods)

- (void) updateButtonState:(NSNotification*)notification;

@end

@implementation EditFilterWindowControl

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) init {         
  if (self = [super initWithWindowNibName:@"EditFilterWindow" owner:self]) {
    allTestsByName = [[NSMutableDictionary alloc] initWithCapacity:32];
    
    // TEMP: Init with some basic tests.
    // TODO: Should (elsewhere) get this from user defaults eventually.
    NSMutableArray  *imageExtensions = 
      [NSMutableArray arrayWithCapacity:16];
    [imageExtensions addObject:@".jpg"];
    [imageExtensions addObject:@".JPG"];
    [imageExtensions addObject:@".png"];
    [imageExtensions addObject:@".PNG"];
    [imageExtensions addObject:@".gif"];
    [imageExtensions addObject:@".GIF"];
    NSObject <StringTest>  *imageExtensionTest = 
      [[[StringSuffixTest alloc] initWithMatches:imageExtensions] autorelease];
    NSObject <FileItemTest>  *imageTest =
      [[FileNameTest alloc] initWithName:@"Images" 
                              stringTest:imageExtensionTest];
    [allTestsByName setObject:imageTest forKey:[imageTest name]];
    
    NSMutableArray  *musicExtensions = 
      [NSMutableArray arrayWithCapacity:16];
    [musicExtensions addObject:@".mp3"];
    [musicExtensions addObject:@".MP3"];
    [musicExtensions addObject:@".wav"];
    [musicExtensions addObject:@".WAV"];
    NSObject <StringTest>  *musicExtensionTest = 
      [[[StringSuffixTest alloc] initWithMatches:musicExtensions] autorelease];
    NSObject <FileItemTest>  *musicTest =
      [[FileNameTest alloc] initWithName:@"Music" 
                              stringTest:musicExtensionTest];
    [allTestsByName setObject:musicTest forKey:[musicTest name]];    

    NSMutableArray  *versionControlFolders = 
      [NSMutableArray arrayWithCapacity:16];
    [versionControlFolders addObject:@"CVS"];
    [versionControlFolders addObject:@".svn"];
    NSObject <StringTest>  *versionControlNameTest = 
      [[[StringEqualityTest alloc] initWithMatches:versionControlFolders] 
        autorelease];
    NSObject <FileItemTest>  *versionControlTest =
      [[DirectoryNameTest alloc] initWithName:@"Version control" 
                                   stringTest:versionControlNameTest];
    [allTestsByName setObject:versionControlTest 
                       forKey:[versionControlTest name]];
                       
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
  
  [super dealloc];
}


- (void) windowDidLoad {
  [filterTestsBrowser setDelegate:self];
  [availableTestsBrowser setDelegate:self];
    
  [[self window] setReleasedWhenClosed:NO];
  
  [filterActionButton removeAllItems];
  [filterActionButton addItemWithTitle:@"Show only"];
  [filterActionButton addItemWithTitle:@"Do not show"];
  
  [self updateButtonState:nil];
}


- (IBAction) cancelFilter:(id)sender {
  [NSApp abortModal];
}

- (IBAction) performFilter:(id)sender {
  [NSApp stopModal];
}

- (IBAction) addTestToRepository:(id)sender {
  // void
}

- (IBAction) removeTestFromRepository:(id)sender {
  // void
}

- (IBAction) editTestInRepository:(id)sender {
  // void
}

- (IBAction) addTestToFilter:(id)sender {
  NSString  *testName = [[availableTestsBrowser selectedCell] stringValue];
  
  if (testName != nil) {
    [filterTests addObject:testName];
    [availableTests removeObject:testName];
    
    [filterTestsBrowser validateVisibleColumns];
    [availableTestsBrowser validateVisibleColumns];

    [self updateButtonState:nil];
  }
}

- (IBAction) removeTestFromFilter:(id)sender {
  NSString  *testName = [[filterTestsBrowser selectedCell] stringValue];
  
  if (testName != nil) {
    [availableTests addObject:testName];
    [filterTests removeObject:testName];

    [filterTestsBrowser validateVisibleColumns];
    [availableTestsBrowser validateVisibleColumns];
    
    [self updateButtonState:nil];
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
  [self updateButtonState:nil];
}

@end

@implementation EditFilterWindowControl (PrivateMethods)

- (void) updateButtonState:(NSNotification*)notification {

  // Find out which test (if any) is currently highlighted.
  NSString  *newSelectedTestName = nil;
  if ([[self window] firstResponder] == 
        [filterTestsBrowser matrixInColumn:0]) {
    newSelectedTestName = [[filterTestsBrowser selectedCell] title];
  }
  else if ([[self window] firstResponder] == 
             [availableTestsBrowser matrixInColumn:0]) {
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
  BOOL  availableTestSelected = ([availableTestsBrowser selectedCell] != nil);

  [removeTestFromRepositoryButton setEnabled:availableTestSelected];
  [editTestInRepositoryButton setEnabled:availableTestSelected];
  [addTestToFilterButton setEnabled:availableTestSelected];

  [removeTestFromFilterButton setEnabled: 
    ([filterTestsBrowser selectedCell] != nil)];

  [performFilterButton setEnabled: ([filterTests count] > 0)];
}

@end
