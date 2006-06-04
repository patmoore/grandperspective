#import <Cocoa/Cocoa.h>


@interface EditFilterRuleWindowControl : NSWindowController {

  IBOutlet NSTextField  *ruleNameField;
  
  IBOutlet NSButton  *typeCheckBox;
  IBOutlet NSPopUpButton  *typePopUpButton;

  IBOutlet NSButton  *nameCheckBox;
  IBOutlet NSPopUpButton  *nameMatchPopUpButton;
  IBOutlet NSTextView  *nameTargetsView;

  IBOutlet NSButton  *sizeLowerBoundCheckBox;
  IBOutlet NSTextField  *sizeLowerBoundField;
  IBOutlet NSPopUpButton  *sizeLowerBoundUnits;
    
  IBOutlet NSButton  *sizeUpperBoundCheckBox;
  IBOutlet NSTextField  *sizeUpperBoundField;
  IBOutlet NSPopUpButton  *sizeUpperBoundUnits;

  IBOutlet NSButton  *doneButton;
}

- (IBAction) cancelEdit:(id)sender;
- (IBAction) doneEditing:(id)sender;

@end
