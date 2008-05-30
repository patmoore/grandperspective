#import "EditFilterRuleWindowControl.h"

#import "FileItem.h"

#import "FileItemTest.h"
#import "CompoundAndItemTest.h"
#import "ItemNameTest.h"
#import "ItemPathTest.h"
#import "ItemSizeTest.h"
#import "ItemFlagsTest.h"
#import "SelectiveItemTest.h"

#import "MultiMatchStringTest.h"
#import "StringEqualityTest.h"
#import "StringContainmentTest.h"
#import "StringPrefixTest.h"
#import "StringSuffixTest.h"

#import "EditFilterWindowControl.h"


// ruleTargetPopUp choices
#define POPUP_FILES              0
#define POPUP_FOLDERS            1
#define POPUP_FILES_AND_FOLDERS  2

// nameMatchPopUp and pathMatchPopUp choices
#define POPUP_STRING_IS           0
#define POPUP_STRING_CONTAINS     1
#define POPUP_STRING_STARTS_WITH  2
#define POPUP_STRING_ENDS_WITH    3

// hardLinkStatusPopUp and packageStatusPopUp
#define POPUP_FLAG_IS      0
#define POPUP_FLAG_IS_NOT  1

// sizeLowerBoundsUnits and sizeUpperBoundsUnits choices
#define POPUP_BYTES  0
#define POPUP_KB     1
#define POPUP_MB     2
#define POPUP_GB     3


@interface EditFilterRuleWindowControl (PrivateMethods) 

- (void) resetState;
- (void) updateStateBasedOnTest: (NSObject <FileItemTest> *)test;
- (void) updateStateBasedOnItemNameTest: (ItemNameTest *)test;
- (void) updateStateBasedOnItemPathTest: (ItemPathTest *)test;
- (void) updateStateBasedOnItemSizeTest: (ItemSizeTest *)test;
- (void) updateStateBasedOnItemFlagsTest: (ItemFlagsTest *)test;
- (NSObject <FileItemTest> *) updateStateBasedOnSelectiveItemTest: 
                                (SelectiveItemTest *)test;

- (ItemNameTest *) itemNameTestBasedOnState;
- (ItemPathTest *) itemPathTestBasedOnState;
- (ItemSizeTest *) itemSizeTestBasedOnState;
- (ItemFlagsTest *) itemFlagsTestBasedOnState;
- (NSObject <FileItemTest> *) selectiveItemTestBasedOnState:
     (NSObject <FileItemTest> *) subTest;

@end // @interface EditFilterRuleWindowControl (PrivateMethods)


@interface StringBasedTestControls : NSObject {
  NSButton  *enabledCheckBox;
  NSPopUpButton  *matchPopUpButton;
  NSTableView  *targetsView;
  NSButton  *caseInsensitiveCheckBox;
  NSButton  *addTargetButton;
  NSButton  *removeTargetButton;
  
  NSMutableArray  *matchTargets;
  BOOL  enabled;
  
  /* Tracks if an edit of a match is in progress. If so, the list of matches
   * should not be manipulated, or the table ends up in an inconsistent state.
   */
  BOOL  editInProgress;
}
 
- (id) initWithEnabledCheckBox: (NSButton *)enabledCheckBox 
         matchModePopUpButton: (NSPopUpButton *)popUpButton
         targetsView: (NSTableView *)targetsView
         caseInsensitiveCheckBox: (NSButton *)caseCheckBox
         addTargetButton: (NSButton *)addTargetButton
         removeTargetButton: (NSButton *)removeTargetButton;

- (void) resetState;

- (void) setEnabled: (BOOL)enabled;

- (BOOL) hasTargets;
- (void) addTarget;
- (void) removeTarget;

- (void) updateStateBasedOnStringTest:(MultiMatchStringTest*) test;
- (MultiMatchStringTest*) stringTestBasedOnState;

@end // @interface StringBasedTestControls


@interface StringBasedTestControls (PrivateMethods)

- (void) updateEnabledState;

- (void) didBeginEditing: (NSNotification *)notification;
- (void) didEndEditing: (NSNotification *)notification;

@end // @interface StringBasedTestControls (PrivateMethods)


@implementation EditFilterRuleWindowControl

EditFilterRuleWindowControl  *defaultEditFilterRuleWindowControlInstance = nil;

+ (id) defaultInstance {
  if (defaultEditFilterRuleWindowControlInstance == nil) {
    defaultEditFilterRuleWindowControlInstance = 
      [[EditFilterRuleWindowControl alloc] init];
  }
  
  return defaultEditFilterRuleWindowControlInstance;
}

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) init {         
  if (self = [super initWithWindowNibName:@"EditFilterRuleWindow" owner:self]) {
    // void
  }
  return self;
}


- (void) dealloc {
  [nameTestControls release];
  [pathTestControls release];
  [ruleName release];

  [super dealloc];
}


- (void) windowDidLoad {
  nameTestControls = [[StringBasedTestControls alloc]
                         initWithEnabledCheckBox: nameCheckBox
                         matchModePopUpButton: nameMatchPopUpButton
                         targetsView: nameTargetsView
                         caseInsensitiveCheckBox: nameCaseInsensitiveCheckBox
                         addTargetButton: addNameTargetButton
                         removeTargetButton: removeNameTargetButton];
  pathTestControls = [[StringBasedTestControls alloc]
                         initWithEnabledCheckBox: pathCheckBox
                         matchModePopUpButton: pathMatchPopUpButton
                         targetsView: pathTargetsView
                         caseInsensitiveCheckBox: pathCaseInsensitiveCheckBox
                         addTargetButton: addPathTargetButton
                         removeTargetButton: removePathTargetButton];

  [self updateEnabledState: nil];
}


- (NSString*) fileItemTestName {
  if ([ruleNameField isEnabled]) {
    // No fixed "visible" name was set, so get the name from the text field.
    return [ruleNameField stringValue];
  }
  else {
    // The rule name field was showing the rule's visible name. Return its
    // original name.
    return ruleName;
  }
}

// Configures the window to represent the given test.
- (void) representFileItemTest:(NSObject <FileItemTest> *)test {
  [self resetState];
  
  if (test == nil) {
    // No test specified. Leave window in default state.
    return;
  }
  
  // Remember the original name of the rule
  [ruleName release];
  ruleName = [[test name] retain];
  
  [ruleNameField setStringValue: ruleName];
  
  if ([test isKindOfClass: [SelectiveItemTest class]]) {
    // It is a selective test. Update state and continue with its subtest
    
    test = [self updateStateBasedOnSelectiveItemTest: 
                   (SelectiveItemTest *)test];
  }
  else {
    [ruleTargetPopUp selectItemAtIndex: POPUP_FILES_AND_FOLDERS];
  }

  
  if ([test isKindOfClass:[CompoundAndItemTest class]]) {
    // It is a compound test. Iterate over all subtests.
    NSEnumerator  *subTests = 
      [[((CompoundAndItemTest*)test) subItemTests] objectEnumerator];
    NSObject <FileItemTest>  *subTest;
    while (subTest = [subTests nextObject]) {
      [self updateStateBasedOnTest:subTest];
    } 
  }
  else {
    // It is a stand-alone test.
    [self updateStateBasedOnTest:test];
  }  

  [self updateEnabledState:nil];
}

- (NSObject <FileItemTest> *) createFileItemTest {
  NSMutableArray  *subTests = [NSMutableArray arrayWithCapacity:3];
  NSObject <FileItemTest>  *subTest;
  
  subTest = [self itemNameTestBasedOnState];
  if (subTest != nil) {
    [subTests addObject:subTest];
  }
  
  subTest = [self itemPathTestBasedOnState];
  if (subTest != nil) {
    [subTests addObject:subTest];
  }

  subTest = [self itemSizeTestBasedOnState];
  if (subTest != nil) {
    [subTests addObject:subTest];
  }
  
  subTest = [self itemFlagsTestBasedOnState];
  if (subTest != nil) {
    [subTests addObject:subTest];
  }
  
  NSObject <FileItemTest>  *test;
  if ([subTests count] == 0) {
    test = nil;
  }
  else if ([subTests count] == 1) {
    test = [subTests lastObject];
  }
  else {
    test = [[[CompoundAndItemTest alloc] initWithSubItemTests:subTests]
                autorelease];
  }
  
  test = [self selectiveItemTestBasedOnState: test];
  
  [test setName: [self fileItemTestName]];
  
  return test;
}

- (void) setVisibleName: (NSString *)name {
  [ruleNameField setStringValue: name];
  [ruleNameField setEnabled: NO];
}



- (IBAction) cancelAction:(id)sender {
  if ([[self window] makeFirstResponder: [self window]]) {
    // Only respond to the cancel action when the window can obtain first
    // responder status. If this fails, it means that a field editor is being
    // used that does not want to give up its first responder status because
    // its delegate tells it not to (because its text value is still invalid).
    //
    // The field editor can be made to give up its first responder status
    // by "brute force" using endEditingFor:. However, this then requires
    // extra work to ensure the state is consistent, and does not seem worth
    // the effort.
  
    [[NSNotificationCenter defaultCenter] 
        postNotificationName: CancelPerformedEvent object: self];
  }
}

- (IBAction) okAction:(id)sender {
  if ([[self window] makeFirstResponder: [self window]]) {
    // Only respond to the action when the window can obtain first responder
    // status (see cancelAction:).
  
    [[NSNotificationCenter defaultCenter] 
        postNotificationName: OkPerformedEvent object: self];
  }
}


// Auto-corrects the lower/upper bound fields so that they contain a valid
// numeric value.
- (IBAction)valueEntered:(id)sender {
  int  value = [sender intValue];
  
  if (value < 0) {
    value = 0;
  }
  
  [sender setIntValue: value];
}


- (IBAction) targetPopUpChanged:(id)sender {
  [self updateEnabledState:sender];
}


- (IBAction) nameCheckBoxChanged:(id)sender {
  [self updateEnabledState:sender];
  
  if ([sender state]==NSOnState) {
    [[self window] makeFirstResponder:nameTargetsView];
  }
}

- (IBAction) pathCheckBoxChanged:(id)sender {
  [self updateEnabledState:sender];
  
  if ([sender state]==NSOnState) {
    [[self window] makeFirstResponder:pathTargetsView];
  }
}

- (IBAction) hardLinkCheckBoxChanged: (id)sender {
  [self updateEnabledState: sender];
}

- (IBAction) packageCheckBoxChanged: (id)sender {
  [self updateEnabledState: sender];
}

- (IBAction) typeCheckBoxChanged:(id)sender {
  // TODO
}

- (IBAction) lowerBoundCheckBoxChanged:(id)sender {
  [self updateEnabledState:sender];
  
  if ([sender state]==NSOnState) {
    [[self window] makeFirstResponder:sizeLowerBoundField];
  }
}

- (IBAction) upperBoundCheckBoxChanged:(id)sender {  
  [self updateEnabledState:sender];
  
  if ([sender state]==NSOnState) {
    [[self window] makeFirstResponder:sizeUpperBoundField];
  }
}


- (IBAction) addNameTarget: (id) sender {
  [nameTestControls addTarget];
  [self updateEnabledState: nil];
}

- (IBAction) removeNameTarget: (id) sender {
  [nameTestControls removeTarget];
  [self updateEnabledState: nil];
}

- (IBAction) addPathTarget: (id) sender {
  [pathTestControls addTarget];
  [self updateEnabledState: nil];
}

- (IBAction) removePathTarget: (id) sender {
  [pathTestControls removeTarget];
  [self updateEnabledState: nil];
}


- (IBAction) updateEnabledState:(id)sender {
  // Note: "sender" is ignored. Always updating all.
  
  BOOL  targetsOnlyFiles = [ruleTargetPopUp indexOfSelectedItem]==0;
  
  BOOL  nameTestUsed = [nameCheckBox state]==NSOnState;
  BOOL  pathTestUsed = [pathCheckBox state]==NSOnState;
  BOOL  hardLinkTestUsed = [hardLinkCheckBox state]==NSOnState;
  BOOL  packageTestUsed = [packageCheckBox state]==NSOnState;
  BOOL  typeTestUsed = ( [typeCheckBox state]==NSOnState && targetsOnlyFiles );
  BOOL  lowerBoundTestUsed = ( [sizeLowerBoundCheckBox state]==NSOnState
                               && targetsOnlyFiles );
  BOOL  upperBoundTestUsed = ( [sizeUpperBoundCheckBox state]==NSOnState
                               && targetsOnlyFiles );
  
  [nameTestControls setEnabled: nameTestUsed];
  [pathTestControls setEnabled: pathTestUsed];

  [hardLinkStatusPopUp setEnabled: hardLinkTestUsed];
  [packageStatusPopUp setEnabled: packageTestUsed];
  
  [typeCheckBox setEnabled: targetsOnlyFiles];
  // TODO: [typeTestControls setEnabled: typeTestUsed];
  
  [sizeLowerBoundCheckBox setEnabled: targetsOnlyFiles];
  [sizeLowerBoundField setEnabled: lowerBoundTestUsed];
  [sizeLowerBoundUnits setEnabled: lowerBoundTestUsed];

  [sizeUpperBoundCheckBox setEnabled: targetsOnlyFiles];
  [sizeUpperBoundField setEnabled: upperBoundTestUsed];
  [sizeUpperBoundUnits setEnabled: upperBoundTestUsed];

  [doneButton setEnabled:
     [[ruleNameField stringValue] length] > 0
     && ( ( nameTestUsed && [nameTestControls hasTargets] )
          || ( pathTestUsed && [pathTestControls hasTargets] )
          || lowerBoundTestUsed 
          || upperBoundTestUsed 
          || hardLinkTestUsed
          || packageTestUsed) ];
}

@end


@implementation EditFilterRuleWindowControl (PrivateMethods) 

- (void) resetState {
  [ruleNameField setStringValue: @""];
  [ruleNameField setEnabled: YES];
  
  [ruleTargetPopUp selectItemAtIndex: POPUP_FILES];

  [nameTestControls resetState];
  [pathTestControls resetState];

  [sizeLowerBoundCheckBox setState: NSOffState];
  [sizeLowerBoundField setIntValue: 0];
  [sizeLowerBoundUnits selectItemAtIndex: POPUP_BYTES];
  
  [sizeUpperBoundCheckBox setState: NSOffState];
  [sizeUpperBoundField setIntValue: 0];
  [sizeUpperBoundUnits selectItemAtIndex: POPUP_BYTES];
  
  [hardLinkCheckBox setState: NSOffState];
  [hardLinkStatusPopUp selectItemAtIndex: POPUP_FLAG_IS];

  [packageCheckBox setState: NSOffState];
  [packageStatusPopUp selectItemAtIndex: POPUP_FLAG_IS];
  
  [self updateEnabledState: nil];
}


- (void) updateStateBasedOnTest:(NSObject <FileItemTest> *)test {
  if ([test isKindOfClass: [ItemNameTest class]]) {
    [self updateStateBasedOnItemNameTest: (ItemNameTest *)test];
  }
  else if ([test isKindOfClass: [ItemPathTest class]]) {
    [self updateStateBasedOnItemPathTest: (ItemPathTest *)test];
  }
  else if ([test isKindOfClass: [ItemSizeTest class]]) {
    [self updateStateBasedOnItemSizeTest: (ItemSizeTest *)test];
  }
  else if ([test isKindOfClass: [ItemFlagsTest class]]) {
    [self updateStateBasedOnItemFlagsTest: (ItemFlagsTest *)test];
  }

  else {
    NSAssert(NO, @"Unexpected test.");
  }
}


- (void) updateStateBasedOnItemNameTest: (ItemNameTest *)test {
  MultiMatchStringTest  *stringTest = (MultiMatchStringTest*)[test stringTest];
  
  [nameTestControls updateStateBasedOnStringTest: stringTest];
}


- (void) updateStateBasedOnItemPathTest: (ItemPathTest *)test {
  MultiMatchStringTest  *stringTest = (MultiMatchStringTest*)[test stringTest];
  
  [pathTestControls updateStateBasedOnStringTest: stringTest];
}


- (void) updateStateBasedOnItemSizeTest: (ItemSizeTest *)test {
  if ([test hasLowerBound]) {
    ITEM_SIZE  bound = [test lowerBound];
    int  i = POPUP_BYTES;
    
    if (bound > 0) {
      while (i < POPUP_GB && (bound % 1024)==0) {
        i++;
        bound /= 1024;
      }
    }
    
    [sizeLowerBoundCheckBox setState:NSOnState];    
    [sizeLowerBoundField setIntValue:bound];
    [sizeLowerBoundUnits selectItemAtIndex:i]; 
  }

  if ([test hasUpperBound]) {
    ITEM_SIZE  bound = [test upperBound];
    int  i = POPUP_BYTES;
          
    if (bound > 0) {
      while (i < POPUP_GB && (bound % 1024)==0) {
        i++;
        bound /= 1024;
      }
    }
    
    [sizeUpperBoundCheckBox setState:NSOnState];
    [sizeUpperBoundField setIntValue:bound];
    [sizeUpperBoundUnits selectItemAtIndex:i];
  }
}


- (void) updateStateBasedOnItemFlagsTest: (ItemFlagsTest *)test {
  if ([test flagsMask] & FILE_IS_HARDLINKED) {
    [hardLinkCheckBox setState: NSOnState];
    
    [hardLinkStatusPopUp selectItemAtIndex: 
       ( ([test desiredResult] & FILE_IS_HARDLINKED) 
         ? POPUP_FLAG_IS 
         : POPUP_FLAG_IS_NOT ) ];
  }
  
  if ([test flagsMask] & FILE_IS_PACKAGE) {
    [packageCheckBox setState: NSOnState];
    
    [packageStatusPopUp selectItemAtIndex: 
       ( ([test desiredResult] & FILE_IS_PACKAGE) 
         ? POPUP_FLAG_IS 
         : POPUP_FLAG_IS_NOT ) ];
  }
}


- (NSObject <FileItemTest> *) updateStateBasedOnSelectiveItemTest: 
                                (SelectiveItemTest *)test {
  [ruleTargetPopUp selectItemAtIndex: ( [test applyToFilesOnly] 
                                        ? POPUP_FILES 
                                        : POPUP_FOLDERS ) ];
  
  return [test subItemTest];
}


- (ItemNameTest*) itemNameTestBasedOnState {
  MultiMatchStringTest  *stringTest = [nameTestControls stringTestBasedOnState];

  if (stringTest != nil) {
    return [[[ItemNameTest alloc] initWithStringTest:stringTest] autorelease];
  }
  else {
    return nil;
  }
}


- (ItemPathTest*) itemPathTestBasedOnState {
  MultiMatchStringTest  *stringTest = [pathTestControls stringTestBasedOnState];
  
  if (stringTest != nil) {
    return [[[ItemPathTest alloc] initWithStringTest:stringTest] autorelease];
  }
  else {
    return nil;
  }
}


- (ItemSizeTest*) itemSizeTestBasedOnState {
  ITEM_SIZE  lowerBound = MAX(0, [sizeLowerBoundField intValue]);
  int  i = [sizeLowerBoundUnits indexOfSelectedItem];
  while (i-- > 0) {
    lowerBound *= 1024;
  }

  ITEM_SIZE  upperBound = MAX(0, [sizeUpperBoundField intValue]);
  i = [sizeUpperBoundUnits indexOfSelectedItem];
  while (i-- > 0) {
    upperBound *= 1024;
  }
  
  if ([sizeLowerBoundCheckBox state]==NSOnState && lowerBound>0) {
    if ([sizeUpperBoundCheckBox state]==NSOnState) {
      return [[[ItemSizeTest alloc] 
                  initWithLowerBound:lowerBound upperBound:upperBound] 
                  autorelease];
    }
    else {
      return [[[ItemSizeTest alloc] initWithLowerBound:lowerBound] autorelease];    
    }
  }
  else {
    if ([sizeUpperBoundCheckBox state]==NSOnState) {
      return [[[ItemSizeTest alloc] initWithUpperBound:upperBound] autorelease];
    }
    else {
      return nil;
    }
  }
}


- (ItemFlagsTest *) itemFlagsTestBasedOnState {
  UInt8  flagsMask = 0;
  UInt8  desiredResult = 0;
  
  if ([hardLinkCheckBox state] == NSOnState) {
    flagsMask |= FILE_IS_HARDLINKED;
    if ([hardLinkStatusPopUp indexOfSelectedItem] == POPUP_FLAG_IS) {
      desiredResult |= FILE_IS_HARDLINKED;
    }
  }
  
  if ([packageCheckBox state] == NSOnState) {
    flagsMask |= FILE_IS_PACKAGE;
    if ([packageStatusPopUp indexOfSelectedItem] == POPUP_FLAG_IS) {
      desiredResult |= FILE_IS_PACKAGE;
    }
  }
  
  if (flagsMask) {
    return [[[ItemFlagsTest alloc] initWithFlagsMask: flagsMask  
                                     desiredResult: desiredResult] autorelease];
  }
  else {
    return nil;
  }
}


- (NSObject <FileItemTest> *) selectiveItemTestBasedOnState:
     (NSObject <FileItemTest> *) subTest {
  int  index = [ruleTargetPopUp indexOfSelectedItem];
  
  if (index == POPUP_FILES_AND_FOLDERS) { 
    return subTest;
  }
  else {
    BOOL  onlyFiles = (index == POPUP_FILES);
  
    return [[[SelectiveItemTest alloc] initWithSubItemTest: subTest 
                                         onlyFiles: onlyFiles] autorelease];
  } 
}

@end


@implementation StringBasedTestControls

- (id) initWithEnabledCheckBox: (NSButton *)enabledCheckBoxVal
         matchModePopUpButton: (NSPopUpButton *)popUpButton
         targetsView: (NSTableView *)targetsTableViewVal
         caseInsensitiveCheckBox: (NSButton *)caseCheckBox
         addTargetButton: (NSButton *)addButton
         removeTargetButton: (NSButton *)removeButton; {
  if (self = [super init]) {
    enabledCheckBox = [enabledCheckBoxVal retain];
    matchPopUpButton = [popUpButton retain];
    targetsView = [targetsTableViewVal retain];
    caseInsensitiveCheckBox = [caseCheckBox retain];
    addTargetButton = [addButton retain];
    removeTargetButton = [removeButton retain];
    
    matchTargets = [[NSMutableArray alloc] initWithCapacity: 4];
    
    [targetsView setDataSource: self];
    [targetsView setDelegate: self];
    
    editInProgress = NO;
    
    NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver: self selector: @selector(didBeginEditing:)
          name: NSControlTextDidBeginEditingNotification object: targetsView];
    [nc addObserver: self selector: @selector(didEndEditing:)
        name: NSControlTextDidEndEditingNotification object: targetsView];
  }
  
  return self;
}

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver: self];

  [enabledCheckBox release];
  [matchPopUpButton release];
  [targetsView release];
  [caseInsensitiveCheckBox release];
  [addTargetButton retain];
  [removeTargetButton retain];
  
  [matchTargets release];

  [super dealloc];
}


- (void) resetState {
  [enabledCheckBox setState: NSOffState];
  [matchPopUpButton selectItemAtIndex: POPUP_STRING_IS];
  [caseInsensitiveCheckBox setState: NSOffState];
  
  [matchTargets removeAllObjects];
  [targetsView reloadData];
}


- (void) setEnabled: (BOOL)enabledVal {
  enabled = enabledVal;
  
  [self updateEnabledState];
}


- (BOOL) hasTargets {
  return [matchTargets count] > 0;
}


- (void) addTarget {
  NSAssert(!editInProgress, @"Cannot edit target while edit in progress.");

  int  newRow =  [matchTargets count];
  
  [matchTargets addObject: 
     NSLocalizedString( @"New match", 
                        @"Initial match value in EditFilterRuleWindow" ) ];
  [targetsView reloadData];
  [targetsView selectRow: newRow byExtendingSelection: NO];
  
  editInProgress = YES;
  [self updateEnabledState];
  
  [targetsView editColumn: 0 row: newRow withEvent: nil select: YES];
}

- (void) removeTarget {
  NSAssert(!editInProgress, @"Cannot remove target while edit in progress.");

  int  selectedRow = [targetsView selectedRow];
  [matchTargets removeObjectAtIndex: selectedRow];

  if (selectedRow == [matchTargets count] && selectedRow > 0) {
    [targetsView selectRow: selectedRow - 1 byExtendingSelection: NO];
  }

  [targetsView reloadData];
  
}


- (void) updateStateBasedOnStringTest: (MultiMatchStringTest *)test {
  [enabledCheckBox setState: NSOnState];

  int  index = -1;
    
  if ([test isKindOfClass:[StringEqualityTest class]]) {
    index = POPUP_STRING_IS;
  }
  else if ([test isKindOfClass:[StringContainmentTest class]]) {
    index = POPUP_STRING_CONTAINS;
  }
  else if ([test isKindOfClass:[StringPrefixTest class]]) {
    index = POPUP_STRING_STARTS_WITH;
  }
  else if ([test isKindOfClass:[StringSuffixTest class]]) {
    index = POPUP_STRING_ENDS_WITH;
  }
  else {
    NSAssert(NO, @"Unknown string test.");
  }
  [matchPopUpButton selectItemAtIndex: index];
  
  [matchTargets removeAllObjects];
  [matchTargets addObjectsFromArray: [test matchTargets]];
  [targetsView reloadData];
  
  [caseInsensitiveCheckBox setState:
     ([test isCaseSensitive] ? NSOffState : NSOnState)];
}


- (MultiMatchStringTest*) stringTestBasedOnState {
  if ([enabledCheckBox state]!=NSOnState) {
    // Test not used.
    return nil; 
  }
  
  if ([matchTargets count] == 0) {
    // No match targets specified.
    return nil;
  }
  
  MultiMatchStringTest  *stringTest = nil;
  switch ([matchPopUpButton indexOfSelectedItem]) {
    case POPUP_STRING_IS: 
      stringTest = [StringEqualityTest alloc]; 
      break;
    case POPUP_STRING_CONTAINS: 
      stringTest = [StringContainmentTest alloc]; 
      break;
    case POPUP_STRING_STARTS_WITH: 
      stringTest = [StringPrefixTest alloc]; 
      break;
    case POPUP_STRING_ENDS_WITH: 
      stringTest = [StringSuffixTest alloc]; 
      break;
    default: NSAssert(NO, @"Unexpected matching index.");
  }
      
  BOOL  caseSensitive = ([caseInsensitiveCheckBox state] == NSOffState);
  stringTest = [[stringTest initWithMatchTargets: matchTargets
                              caseSensitive: caseSensitive] autorelease];
      
  return stringTest;
}


//----------------------------------------------------------------------------
// Delegate methods for NSTable

- (void) tableViewSelectionDidChange: (NSNotification *)notification {
  [self updateEnabledState];
}

- (BOOL) control: (NSControl *)control textShouldEndEditing: (NSText *)editor {
  return [[editor string] length] > 0;
}


//----------------------------------------------------------------------------
// NSTableSource

- (int) numberOfRowsInTableView: (NSTableView *)tableView {
  return [matchTargets count];
}

- (id) tableView: (NSTableView *)tableView 
         objectValueForTableColumn: (NSTableColumn *)column row: (int) row {
  return [matchTargets objectAtIndex: row];
}

- (void) tableView: (NSTableView *)tableView setObjectValue: (id) object 
           forTableColumn: (NSTableColumn *)column row: (int) row {
  [matchTargets replaceObjectAtIndex: row withObject: object];
}

- (BOOL) tableView: (NSTableView *)tableView 
           shouldEditTableColumn: (NSTableColumn *)column row: (int) row {
  // Switch to "edit in progress" mode immediately. If not done here, the
  // notification is only sent when the first change is made to the text.
  // However, we like to disable the Remove button as soon as the field editor
  // is active. Otherwise, removal will first remove the cell, then stop the
  // field editor, which overwrites the old value over what has become a
  // different target alltogether.
  [self didBeginEditing: nil];

  return YES;
}


@end // implementation StringBasedTestControls


@implementation StringBasedTestControls (PrivateMethods)

- (void) updateEnabledState {
  [matchPopUpButton setEnabled: enabled];
  [targetsView setEnabled: enabled];
  [caseInsensitiveCheckBox setEnabled: enabled];
  [addTargetButton setEnabled: enabled && !editInProgress];
  [removeTargetButton setEnabled: (enabled && !editInProgress 
                                   && [targetsView numberOfSelectedRows] > 0 )];
}


- (void) didBeginEditing: (NSNotification *)notification {
  editInProgress = YES;
  
  [self updateEnabledState];
}

- (void) didEndEditing: (NSNotification *)notification {
  editInProgress = NO;

  [self updateEnabledState];
}

@end // @implementation StringBasedTestControls (PrivateMethods)
