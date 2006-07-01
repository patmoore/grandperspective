#import "EditFilterRuleWindowControl.h"

#import "filter/FileItemTest.h"
#import "filter/CompoundAndItemTest.h"
#import "filter/ItemNameTest.h"
#import "filter/ItemPathTest.h"
#import "filter/ItemSizeTest.h"

#import "filter/MultiMatchStringTest.h"
#import "filter/StringEqualityTest.h"
#import "filter/StringContainmentTest.h"
#import "filter/StringPrefixTest.h"
#import "filter/StringSuffixTest.h"


// Using this struct for re-using the common code for the string-based test
// on the item name as well as the path of the item.
//
// Note: Although this could be done using proper Objective C class, this is 
// not ideal either as it is best to keep this structure/object short-lived. 
// Otherwise the references to the GUI controls would be stored twice in the 
// EditFitlerRuleWindowControl object, as it is unavoidable to store them 
// individually as IBOutlets. Given that, use of a structure on the stack 
// seems to better fit the short-lived way in that it is used. 
typedef struct {
  NSButton  *enabledCheckBox;
  NSPopUpButton  *matchPopUpButton;
  NSTextView  *targetsView;
} MatchingControls; 

void updateMatchingControlsBasedOnStringTest
  (MatchingControls controls, MultiMatchStringTest *test);

MultiMatchStringTest* stringTestBasedOnMatchingControls
  (MatchingControls controls);


@interface EditFilterRuleWindowControl (PrivateMethods) 

// Note: "state" excludes the name of the test.
- (void) resetState;
- (void) updateStateBasedOnTest:(NSObject <FileItemTest> *)test;
- (void) updateStateBasedOnItemNameTest:(ItemNameTest*)test;
- (void) updateStateBasedOnItemPathTest:(ItemPathTest*)test;
- (void) updateStateBasedOnItemSizeTest:(ItemSizeTest*)test;

- (ItemNameTest*) itemNameTestBasedOnState;
- (ItemPathTest*) itemPathTestBasedOnState;
- (ItemSizeTest*) itemSizeTestBasedOnState;

- (MatchingControls) nameMatchingControls;
- (MatchingControls) pathMatchingControls;

@end


@implementation EditFilterRuleWindowControl

EditFilterRuleWindowControl  *defaultInstance = nil;

+ (id) defaultInstance {
  if (defaultInstance == nil) {
    defaultInstance = [[EditFilterRuleWindowControl alloc] init];
  }
  
  return defaultInstance;
}

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) init {         
  if (self = [super initWithWindowNibName:@"EditFilterRuleWindow" owner:self]) {
    // void
  }
  return self;
}


- (void) windowDidLoad {
  NSLog(@"windowDidLoad %@", [self window]);

  [nameMatchPopUpButton removeAllItems];
  [nameMatchPopUpButton addItemWithTitle:@"is"];
  [nameMatchPopUpButton addItemWithTitle:@"contains"];
  [nameMatchPopUpButton addItemWithTitle:@"starts with"];
  [nameMatchPopUpButton addItemWithTitle:@"ends with"];
  
  // TODO: also set path pop-up button

  NSArray  *sizeUnits = [NSArray arrayWithObjects:@"bytes", @"kB", @"MB", 
                                                  @"GB"];
  [sizeLowerBoundUnits removeAllItems];
  [sizeLowerBoundUnits addItemsWithTitles:sizeUnits];
  [sizeUpperBoundUnits removeAllItems];
  [sizeUpperBoundUnits addItemsWithTitles:sizeUnits];

  [self updateEnabledState:nil];
}


// Configures the window to represent the given test.
- (void) representFileItemTest:(NSObject <FileItemTest> *)test {
  [self resetState];
  
  if (test == nil) {
    // No test specified. Leave window in default state.
    return;
  }
  else if ([test isKindOfClass:[CompoundAndItemTest class]]) {
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

// Creates the test object that represents the current window state.
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
  
  if ([subTests count] == 0) {
    return nil;
  }
  else if ([subTests count] == 1) {
    return [subTests lastObject];
  }
  else {
    return [[[CompoundAndItemTest alloc] initWithSubItemTests:subTests]
                autorelease];
  }
}


- (void) setFileItemTestName:(NSString *)name {
  [ruleNameField setStringValue:name];
  
  [self updateEnabledState:nil];
}

- (NSString*) fileItemTestName {
  return [ruleNameField stringValue];
}


- (IBAction) cancelAction:(id)sender {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"cancelPerformed"
                                          object:self];
}

- (IBAction) okAction:(id)sender {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"okPerformed"
                                          object:self];
}


// Makes sure the lower/upper bounds fields contain a (positive) numeric value.
- (IBAction)valueEntered:(id)sender {
  int  value = [sender intValue];
  
  if (value < 0) {
    value = 0;
  }
  
  [sender setIntValue: value];
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


- (IBAction) updateEnabledState:(id)sender {
  // Note: "sender" is ignored. Always updating all.
  
  BOOL  nameTestUsed = [nameCheckBox state]==NSOnState;
  BOOL  pathTestUsed = [pathCheckBox state]==NSOnState;
  BOOL  lowerBoundTestUsed = [sizeLowerBoundCheckBox state]==NSOnState;
  BOOL  upperBoundTestUsed = [sizeUpperBoundCheckBox state]==NSOnState;
    
  [nameMatchPopUpButton setEnabled:nameTestUsed];
  [nameTargetsView setEditable:nameTestUsed];
  
  [pathMatchPopUpButton setEnabled:pathTestUsed];
  [pathTargetsView setEditable:pathTestUsed];
  
  [sizeLowerBoundField setEnabled:lowerBoundTestUsed];
  [sizeLowerBoundUnits setEnabled:lowerBoundTestUsed];
  [sizeUpperBoundField setEnabled:upperBoundTestUsed];
  [sizeUpperBoundUnits setEnabled:upperBoundTestUsed];

  [doneButton setEnabled:
     (nameTestUsed || pathTestUsed || lowerBoundTestUsed || upperBoundTestUsed) 
     && [[ruleNameField stringValue] length] > 0];
}

@end


void updateMatchingControlsBasedOnStringTest
  (MatchingControls controls, MultiMatchStringTest *test) {
  
  [controls.enabledCheckBox setState: NSOnState];

  int  index = -1;
    
  if ([test isKindOfClass:[StringEqualityTest class]]) {
    index = 0;
  }
  else if ([test isKindOfClass:[StringContainmentTest class]]) {
    index = 1;
  }
  else if ([test isKindOfClass:[StringPrefixTest class]]) {
    index = 2;
  }
  else if ([test isKindOfClass:[StringSuffixTest class]]) {
    index = 3;
  }
  else {
    NSAssert(NO, @"Unknown string test.");
  }
  [controls.matchPopUpButton selectItemAtIndex: index];
  
  // Fill text view.
  NSMutableString  *targetText = [NSMutableString stringWithCapacity:128];
  NSEnumerator  *matchTargets = [[test matchTargets] objectEnumerator];
  NSString*  matchTarget = nil;
  while (matchTarget = [matchTargets nextObject]) {
    [targetText appendString:matchTarget];
    [targetText appendString:@"\n"];
  }
  
  [controls.targetsView setString: nameTargetText];  
}


MultiMatchStringTest* stringTestBasedOnMatchingControls
  (MatchingControls controls) {
     
  if ([controls.enabledCheckBox state]==NSOnState) {
    NSArray  *rawTargets = 
      [[controls.targetsView string] componentsSeparatedByString:@"\n"];
      
    NSMutableArray  *targets = 
      [NSMutableArray arrayWithCapacity:[rawTargets count]];

    // Ignore empty lines
    NSEnumerator  *rawTargetsEnum = [rawTargets objectEnumerator];
    NSString  *target = nil;
    while (target = [rawTargetsEnum nextObject]) {
      if ([target length] > 0) {
        if ([rawTargets count]==1) {
          // Need to copy string, as componentsSeparatedByString: returns the
          // (mutable) string directly if there is only one component.
          [targets addObject:[NSString stringWithString:target]];
        }
        else {
          [targets addObject:target];
        }
      }
    }
    
    if ([targets count] > 0) {
      MultiMatchStringTest  *stringTest = nil;
      switch ([controls.matchPopUpButton indexOfSelectedItem]) {
        case 0: stringTest = [StringEqualityTest alloc]; break;
        case 1: stringTest = [StringContainmentTest alloc]; break;
        case 2: stringTest = [StringPrefixTest alloc]; break;
        case 3: stringTest = [StringSuffixTest alloc]; break;
        default: NSAssert(NO, @"Unexpected matching index.");
      }
      stringTest = [[stringTest initWithMatchTargets:targets] autorelease];
      
      return stringTest;
    }
    else {
      // No match targets specified.
      return nil;
    }
  }
  else {
    // Test not used.
    return nil;
  }
}


@implementation EditFilterRuleWindowControl (PrivateMethods) 

- (void) resetState {
  [typeCheckBox setState:NSOffState];
  [typePopUpButton selectItemAtIndex:0]; // File
  
  [nameCheckBox setState:NSOffState];
  [nameMatchPopUpButton selectItemAtIndex:3]; // Suffix
  [nameTargetsView setString:@""];
  
  [sizeLowerBoundCheckBox setState:NSOffState];
  [sizeLowerBoundField setIntValue:0];
  [sizeLowerBoundUnits selectItemAtIndex:0]; // bytes
  
  [sizeUpperBoundCheckBox setState:NSOffState];
  [sizeUpperBoundField setIntValue:0];
  [sizeUpperBoundUnits selectItemAtIndex:0]; // bytes
  
  [self updateEnabledState:nil];
}


- (void) updateStateBasedOnTest:(NSObject <FileItemTest>*)test {
  if ([test isKindOfClass:[ItemNameTest class]]) {
    [self updateStateBasedOnItemNameTest: (ItemNameTest*)test];
  }
  else if ([test isKindOfClass:[ItemPathTest class]]) {
    [self updateStateBasedOnItemPathTest: (ItemPathTest*)test];
  }
  else if ([test isKindOfClass:[ItemSizeTest class]]) {
    [self updateStateBasedOnItemSizeTest: (ItemSizeTest*)test];
  }
  else {
    NSAssert(NO, @"Unexpected test.");
  }
}


- (void) updateStateBasedOnItemNameTest:(ItemNameTest*)test {
  MatchingControls  controls = [self nameMatchingControls];

  MultiMatchStringTest  *stringTest = (MultiMatchStringTest*)[test stringTest];  
  updateMatchingControlsBasedOnStringTest(controls, stringTest);
}


- (void) updateStateBasedOnItemPathTest:(ItemPathTest*)test {
  MatchingControls  controls = [self nameMatchingControls];

  MultiMatchStringTest  *stringTest = (MultiMatchStringTest*)[test stringTest];  
  updateMatchingControlsBasedOnStringTest(controls, stringTest);
}


- (void) updateStateBasedOnItemSizeTest:(ItemSizeTest*)test {
  if ([test hasLowerBound]) {
    ITEM_SIZE  bound = [test lowerBound];
    int  i = 0;
    while (i < 3 && (bound % 1024)==0) {
      i++;
      bound /= 1024;
    }
    
    [sizeLowerBoundCheckBox setState:NSOnState];    
    [sizeLowerBoundField setIntValue:bound];
    [sizeLowerBoundUnits selectItemAtIndex:i]; 
  }

  if ([test hasUpperBound]) {
    ITEM_SIZE  bound = [test upperBound];
    int  i = 0;
    while (i < 3 && (bound % 1024)==0) {
      i++;
      bound /= 1024;
    }
    
    [sizeUpperBoundCheckBox setState:NSOnState];
    [sizeUpperBoundField setIntValue:bound];
    [sizeUpperBoundUnits selectItemAtIndex:i];
  }
}


- (ItemTypeTest*) itemTypeTestBasedOnState {
  if ([typeCheckBox state]==NSOnState) {
    return [[[ItemTypeTest alloc] initWithTestForPlainFile:
                                    [typePopUpButton indexOfSelectedItem]==0]
                autorelease];
  }
  else {
    return nil;
  }
}


- (ItemNameTest*) itemNameTestBasedOnState {
  MatchingControls  controls = [self nameMatchingControls];

  MultiMatchStringTest  *stringText = 
    stringTestBasedOnMatchingControls(controls);

  if (stringTest != nil) {
    return [[[ItemNameTest alloc] initWithStringTest:stringTest] autorelease];
  }
  else {
    return nil;
  }
}


- (ItemPathTest*) itemPathTestBasedOnState {
  MatchingControls  controls = [self pathMatchingControls];

  MultiMatchStringTest  *stringText = 
    stringTestBasedOnMatchingControls(controls);

  if (stringTest != nil) {
    return [[[ItemPathTest alloc] initWithStringTest:stringTest] autorelease];
  }
  else {
    return nil;
  }
}


- (ItemSizeTest*) itemSizeTestBasedOnState {
  ITEM_SIZE  lowerBound = [sizeLowerBoundField intValue];
  int  i = [sizeLowerBoundUnits indexOfSelectedItem];
  while (i-- > 0) {
    lowerBound *= 1024;
  }

  ITEM_SIZE  upperBound = [sizeUpperBoundField intValue];
  i = [sizeUpperBoundUnits indexOfSelectedItem];
  while (i-- > 0) {
    upperBound *= 1024;
  }
  
  if ([sizeLowerBoundCheckBox state]==NSOnState) {
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


- (MatchingControls) nameMatchingControls {
  MatchingControls  c;
  c.enabledButton = nameCheckBox;
  c.matchPopUpButton = nameMatchPopUpButton;
  c.targetsView = nameTargetsView;

  return c;
}

- (MatchingControls) pathMatchingControls {
  MatchingControls  c;
  c.enabledButton = pathCheckBox;
  c.matchPopUpButton = pathMatchPopUpButton;
  c.targetsView = pathTargetsView;
}

@end
