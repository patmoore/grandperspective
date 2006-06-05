#import "EditFilterRuleWindowControl.h"

#import "filter/FileItemTest.h"
#import "filter/CompoundAndItemTest.h"
#import "filter/ItemTypeTest.h"
#import "filter/ItemNameTest.h"
#import "filter/ItemSizeTest.h"

#import "filter/MultiMatchStringTest.h"
#import "filter/StringEqualityTest.h"
#import "filter/StringContainmentTest.h"
#import "filter/StringPrefixTest.h"
#import "filter/StringSuffixTest.h"


@interface EditFilterRuleWindowControl (PrivateMethods) 

// Note: "state" excludes the name of the test.
- (void) resetState;
- (void) updateStateBasedOnTest:(NSObject <FileItemTest> *)test;
- (void) updateStateBasedOnItemTypeTest:(ItemTypeTest*)test;
- (void) updateStateBasedOnItemNameTest:(ItemNameTest*)test;
- (void) updateStateBasedOnItemSizeTest:(ItemSizeTest*)test;

- (ItemTypeTest*) itemTypeTestBasedOnState;
- (ItemNameTest*) itemNameTestBasedOnState;
- (ItemSizeTest*) itemSizeTestBasedOnState;

@end


@implementation EditFilterRuleWindowControl

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

  [typePopUpButton removeAllItems];
  [typePopUpButton addItemWithTitle:@"file"];
  [typePopUpButton addItemWithTitle:@"folder"];

  [nameMatchPopUpButton removeAllItems];
  [nameMatchPopUpButton addItemWithTitle:@"is"];
  [nameMatchPopUpButton addItemWithTitle:@"contains"];
  [nameMatchPopUpButton addItemWithTitle:@"starts with"];
  [nameMatchPopUpButton addItemWithTitle:@"ends with"];

  NSArray  *sizeUnits = [NSArray arrayWithObjects:@"bytes", @"kB", @"MB", 
                                                  @"GB"];
  [sizeLowerBoundUnits removeAllItems];
  [sizeLowerBoundUnits addItemsWithTitles:sizeUnits];
  [sizeUpperBoundUnits removeAllItems];
  [sizeUpperBoundUnits addItemsWithTitles:sizeUnits];

  [self updateEnabledState:nil];

  [[self window] setReleasedWhenClosed:NO];
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
}

// Creates the test object that represents the current window state.
- (NSObject <FileItemTest> *) createFileItemTest {
  NSMutableArray  *subTests = [NSMutableArray arrayWithCapacity:3];
  NSObject <FileItemTest>  *subTest;
  
  subTest = [self itemTypeTestBasedOnState];
  if (subTest != nil) {
    [subTests addObject:subTest];
  }

  subTest = [self itemNameTestBasedOnState];
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
}

- (NSString*) fileItemTestName {
  return [ruleNameField stringValue];
}


- (IBAction) cancelEdit:(id)sender {
  [NSApp abortModal];
}

- (IBAction) doneEditing:(id)sender {
  [NSApp stopModal];
}


// Makes sure the lower/upper bounds fields contain a (positive) numeric value.
- (IBAction)valueEntered:(id)sender {
  int  value = [sender intValue];
  
  if (value < 0) {
    value = 0;
  }
  
  [sender setIntValue: value];
}


- (IBAction) updateEnabledState:(id)sender {
  // Note: "sender" is ignored. Always updating all.
  
  BOOL  typeTestUsed = [typeCheckBox state]==NSOnState;
  BOOL  nameTestUsed = [nameCheckBox state]==NSOnState;
  BOOL  lowerBoundTestUsed = [sizeLowerBoundCheckBox state]==NSOnState;
  BOOL  upperBoundTestUsed = [sizeUpperBoundCheckBox state]==NSOnState;
    
  [typePopUpButton setEnabled:typeTestUsed];
  
  [nameMatchPopUpButton setEnabled:nameTestUsed];
  [nameTargetsView setEditable:nameTestUsed];
  
  [sizeLowerBoundField setEnabled:lowerBoundTestUsed];
  [sizeLowerBoundUnits setEnabled:lowerBoundTestUsed];
  [sizeUpperBoundField setEnabled:upperBoundTestUsed];
  [sizeUpperBoundUnits setEnabled:upperBoundTestUsed];

  [doneButton setEnabled:
     (typeTestUsed || nameTestUsed || lowerBoundTestUsed || upperBoundTestUsed) 
     && [[ruleNameField stringValue] length] > 0];
}

@end

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
  if ([test isKindOfClass:[ItemTypeTest class]]) {
    [self updateStateBasedOnItemTypeTest: (ItemTypeTest*)test];
  }
  else if ([test isKindOfClass:[ItemNameTest class]]) {
    [self updateStateBasedOnItemNameTest: (ItemNameTest*)test];
  }
  else if ([test isKindOfClass:[ItemSizeTest class]]) {
    [self updateStateBasedOnItemSizeTest: (ItemSizeTest*)test];
  }
  else {
    NSAssert(NO, @"Unexpected test.");
  }
}


- (void) updateStateBasedOnItemTypeTest:(ItemTypeTest*)test {
  [typeCheckBox setState:NSOnState];    
  [typePopUpButton selectItemAtIndex: ([test testsForPlainFile] ? 0 : 1)];
}


- (void) updateStateBasedOnItemNameTest:(ItemNameTest*)test {
  [nameCheckBox setState:NSOnState];
  MultiMatchStringTest  *stringTest = (MultiMatchStringTest*)[test stringTest];
  int  index = -1;
    
  if ([stringTest isKindOfClass:[StringEqualityTest class]]) {
    index = 0;
  }
  else if ([stringTest isKindOfClass:[StringContainmentTest class]]) {
    index = 1;
  }
  else if ([stringTest isKindOfClass:[StringPrefixTest class]]) {
    index = 2;
  }
  else if ([stringTest isKindOfClass:[StringSuffixTest class]]) {
    index = 3;
  }
  else {
    NSAssert(NO, @"Unknown string test.");
  }
  [nameMatchPopUpButton selectItemAtIndex: index];
  
  // Fill text view.
  NSMutableString  *nameTargetText = [NSMutableString stringWithCapacity:128];
  NSEnumerator  *matchTargets = [[stringTest matchTargets] objectEnumerator];
  NSString*  matchTarget = nil;
  while (matchTarget = [matchTargets nextObject]) {
    [nameTargetText appendString:matchTarget];
    [nameTargetText appendString:@"\n"];
  }
  
  [nameTargetsView setString:nameTargetText];
}


- (void) updateStateBasedOnItemSizeTest:(ItemSizeTest*)test {
  if ([test hasLowerBound]) {
    [sizeLowerBoundCheckBox setState:NSOnState];
    [sizeLowerBoundField setIntValue:[test lowerBound]];
    // TODO: set "bytes", "kB", "MB", "GB" value. 
  }

  if ([test hasUpperBound]) {
    [sizeUpperBoundCheckBox setState:NSOnState];
    [sizeUpperBoundField setIntValue:[test upperBound]];
    // TODO: set "bytes", "kB", "MB", "GB" value. 
  }
}


- (ItemTypeTest*) itemTypeTestBasedOnState {
  if ([typeCheckBox isEnabled]) {
    return [[[ItemTypeTest alloc] initWithTestForPlainFile:
                                    [typePopUpButton indexOfSelectedItem]==0]
                autorelease];
  }
  else {
    return nil;
  }
}


- (ItemNameTest*) itemNameTestBasedOnState {
  if ([nameCheckBox isEnabled]) {
    NSArray  *rawTargets = 
      [[nameTargetsView string] componentsSeparatedByString:@"\n"];
      
    NSMutableArray  *targets = 
      [NSMutableArray arrayWithCapacity:[rawTargets count]];

    // Ignore empty lines
    NSEnumerator  *rawTargetsEnum = [rawTargets objectEnumerator];
    NSString  *target = nil;
    while (target = [rawTargetsEnum nextObject]) {
      if ([target length] > 0) {
        [targets addObject:target];
      }
    }
    
    if ([targets count] > 0) {
      MultiMatchStringTest  *stringTest = nil;
      switch ([nameMatchPopUpButton indexOfSelectedItem]) {
        case 0: stringTest = [StringEqualityTest alloc]; break;
        case 1: stringTest = [StringContainmentTest alloc]; break;
        case 2: stringTest = [StringPrefixTest alloc]; break;
        case 3: stringTest = [StringSuffixTest alloc]; break;
        default: NSAssert(NO, @"Unexpected matching index.");
      }
      stringTest = [stringTest initWithMatchTargets:targets];
      
      return [[[ItemNameTest alloc] initWithStringTest:stringTest] autorelease];
    }
    else {
      // No match targets specified.
      return nil;
    }
  }
  else {
    // Test not enabled.
    return nil;
  }
}


- (ItemSizeTest*) itemSizeTestBasedOnState {
  if ([sizeLowerBoundCheckBox isEnabled]) {
    if ([sizeUpperBoundCheckBox isEnabled]) {
      return [[[ItemSizeTest alloc] 
                  initWithLowerBound:[sizeLowerBoundField intValue] 
                          upperBound:[sizeUpperBoundField intValue]] 
                  autorelease];
    }
    else {
      return [[[ItemSizeTest alloc] 
                  initWithLowerBound:[sizeLowerBoundField intValue]] 
                  autorelease];    
    }
  }
  else {
    if ([sizeUpperBoundCheckBox isEnabled]) {
      return [[[ItemSizeTest alloc] 
                  initWithUpperBound:[sizeUpperBoundField intValue]] 
                  autorelease];
    }
    else {
      return nil;
    }
  }
}

@end
