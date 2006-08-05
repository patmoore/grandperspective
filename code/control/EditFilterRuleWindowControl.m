#import "EditFilterRuleWindowControl.h"

#import "FileItemTest.h"
#import "CompoundAndItemTest.h"
#import "ItemNameTest.h"
#import "ItemPathTest.h"
#import "ItemSizeTest.h"

#import "MultiMatchStringTest.h"
#import "StringEqualityTest.h"
#import "StringContainmentTest.h"
#import "StringPrefixTest.h"
#import "StringSuffixTest.h"


@interface EditFilterRuleWindowControl (PrivateMethods) 

- (void) resetState;
- (void) updateStateBasedOnTest:(NSObject <FileItemTest> *)test;
- (void) updateStateBasedOnItemNameTest:(ItemNameTest*)test;
- (void) updateStateBasedOnItemPathTest:(ItemPathTest*)test;
- (void) updateStateBasedOnItemSizeTest:(ItemSizeTest*)test;

- (ItemNameTest*) itemNameTestBasedOnState;
- (ItemPathTest*) itemPathTestBasedOnState;
- (ItemSizeTest*) itemSizeTestBasedOnState;

@end // @interface EditFilterRuleWindowControl (PrivateMethods)


@interface StringBasedTestControls : NSObject {
  NSButton  *enabledCheckBox;
  NSPopUpButton  *matchPopUpButton;
  NSTextView  *targetsTextView;
}

- (id) initWithEnabledCheckBox:(NSButton*)checkBox 
         matchModePopUpButton:(NSPopUpButton*)popUpButton
         targetsTextView:(NSTextView*)textView;

- (void) resetState;

- (void) updateStateBasedOnStringTest:(MultiMatchStringTest*) test;
- (MultiMatchStringTest*) stringTestBasedOnState;

@end // @interface StringBasedTestControls


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


- (void) dealloc {
  [nameTestControls release];
  [pathTestControls release];

  [super dealloc];
}


- (void) windowDidLoad {
  nameTestControls = [[StringBasedTestControls alloc]
                         initWithEnabledCheckBox: nameCheckBox
                         matchModePopUpButton: nameMatchPopUpButton
                         targetsTextView: nameTargetsView];
  pathTestControls = [[StringBasedTestControls alloc]
                         initWithEnabledCheckBox: pathCheckBox
                         matchModePopUpButton: pathMatchPopUpButton
                         targetsTextView: pathTargetsView];

  NSArray  *sizeUnits = [NSArray arrayWithObjects:@"bytes", @"kB", @"MB", 
                                                  @"GB", nil];
  [sizeLowerBoundUnits removeAllItems];
  [sizeLowerBoundUnits addItemsWithTitles:sizeUnits];
  [sizeUpperBoundUnits removeAllItems];
  [sizeUpperBoundUnits addItemsWithTitles:sizeUnits];

  [self updateEnabledState:nil];
}


- (NSString*) fileItemTestName {
  return [ruleNameField stringValue];
}

// Configures the window to represent the given test.
- (void) representFileItemTest:(NSObject <FileItemTest> *)test {
  [self resetState];
  
  if (test == nil) {
    // No test specified. Leave window in default state.
    return;
  }
  
  [ruleNameField setStringValue:[test name]];
  
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

  [test setName:[ruleNameField stringValue]];
  
  return test;
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


@implementation EditFilterRuleWindowControl (PrivateMethods) 

- (void) resetState {
  [ruleNameField setStringValue:@""];

  [nameTestControls resetState];
  [pathTestControls resetState];

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
  MultiMatchStringTest  *stringTest = (MultiMatchStringTest*)[test stringTest];
  
  [nameTestControls updateStateBasedOnStringTest:stringTest];
}


- (void) updateStateBasedOnItemPathTest:(ItemPathTest*)test {
  MultiMatchStringTest  *stringTest = (MultiMatchStringTest*)[test stringTest];
  
  [pathTestControls updateStateBasedOnStringTest:stringTest];
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

@end


@implementation StringBasedTestControls

- (id) initWithEnabledCheckBox:(NSButton*)checkBox 
         matchModePopUpButton:(NSPopUpButton*)popUpButton
         targetsTextView:(NSTextView*)textView {
  if (self = [super init]) {
    enabledCheckBox = [checkBox retain];
    matchPopUpButton = [popUpButton retain];
    targetsTextView = [textView retain];
    
    [matchPopUpButton removeAllItems];
    [matchPopUpButton addItemWithTitle:@"is"];
    [matchPopUpButton addItemWithTitle:@"contains"];
    [matchPopUpButton addItemWithTitle:@"starts with"];
    [matchPopUpButton addItemWithTitle:@"ends with"];
  }
  
  return self;
}

- (void) dealloc {
  [enabledCheckBox release];
  [matchPopUpButton release];
  [targetsTextView release];

  [super dealloc];
}


- (void) resetState {
  [enabledCheckBox setState:NSOffState];
  [matchPopUpButton selectItemAtIndex:3]; // Suffix
  [targetsTextView setString:@""];
}


- (void) updateStateBasedOnStringTest:(MultiMatchStringTest*) test {
  [enabledCheckBox setState: NSOnState];

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
  [matchPopUpButton selectItemAtIndex: index];
  
  // Fill text view.
  NSMutableString  *targetText = [NSMutableString stringWithCapacity:128];
  NSEnumerator  *matchTargets = [[test matchTargets] objectEnumerator];
  NSString*  matchTarget = nil;
  while (matchTarget = [matchTargets nextObject]) {
    [targetText appendString:matchTarget];
    [targetText appendString:@"\n"];
  }
  
  [targetsTextView setString: targetText];  
}


- (MultiMatchStringTest*) stringTestBasedOnState {
  if ([enabledCheckBox state]==NSOnState) {
    NSArray  *rawTargets = 
      [[targetsTextView string] componentsSeparatedByString:@"\n"];
      
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
      switch ([matchPopUpButton indexOfSelectedItem]) {
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

@end // implementation StringBasedTestControls
