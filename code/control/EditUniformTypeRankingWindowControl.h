#import <Cocoa/Cocoa.h>


@class UniformTypeRanking;

@interface EditUniformTypeRankingWindowControl : NSWindowController  {

  IBOutlet NSBrowser  *typesBrowser;

  IBOutlet NSTextView  *typeDescriptionView;
  IBOutlet NSDrawer  *typeDescriptionDrawer;
  
  IBOutlet NSButton  *moveToTopButton;
  IBOutlet NSButton  *moveToBottomButton;

  IBOutlet NSButton  *revealButton;
  IBOutlet NSButton  *hideButton;

  IBOutlet NSButton  *moveUpButton;
  IBOutlet NSButton  *moveDownButton;

  UniformTypeRanking  *typeRanking;
  NSMutableArray  *typeCells;
}

- (IBAction) cancelAction: (id) sender;
- (IBAction) okAction: (id) sender;

- (IBAction) moveToTopAction: (id) sender;
- (IBAction) moveToBottomAction: (id) sender;

- (IBAction) moveToRevealAction: (id) sender;
- (IBAction) moveToHideAction: (id) sender;

- (IBAction) moveUpAction: (id) sender;
- (IBAction) moveDownAction: (id) sender;

- (IBAction) handleBrowserClick: (id) sender;


- (id) initWithUniformTypeRanking: (UniformTypeRanking *)typeRanking;

@end
