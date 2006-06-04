#import <Cocoa/Cocoa.h>


@interface EditFilterRuleWindowControl : NSWindowController {

  IBOutlet NSTextField  *ruleNameField;

  IBOutlet NSPopUpButton  *ruleTargetButton;
  IBOutlet NSPopUpButton  *ruleTestButton;
  
  IBOutlet NSTextView  *ruleTargetsView;

  IBOutlet NSButton  *doneButton;

}

- (IBAction) cancelEdit:(id)sender;
- (IBAction) doneEditing:(id)sender;

@end
