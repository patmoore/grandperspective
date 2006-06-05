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

// Configures the window to represent the given test.
- (void) representFileItemTest:(NSObject <FileItemTest> *)test {
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
    
  return nil; // TODO
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

@end

@implementation EditFilterRuleWindowControl (PrivateMethods) 

- (void) resetState {
  [typeCheckBox setEnabled:NO];
  [nameCheckBox setEnabled:NO];
  [sizeLowerBoundCheckBox setEnabled:NO];
  [sizeUpperBoundCheckBox setEnabled:NO];
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
  [typeCheckBox setEnabled:YES];    
  [typePopUpButton selectItemAtIndex: ([test testsForPlainFile] ? 0 : 1)];
}


- (void) updateStateBasedOnItemNameTest:(ItemNameTest*)test {
  [nameCheckBox setEnabled:YES];
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
    [sizeLowerBoundCheckBox setEnabled:YES];
    [sizeLowerBoundField setIntValue:[test lowerBound]];
    // TODO: set "bytes", "kB", "MB", "GB" value. 
  }

  if ([test hasUpperBound]) {
    [sizeUpperBoundCheckBox setEnabled:YES];
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
