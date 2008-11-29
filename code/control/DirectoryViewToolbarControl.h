#import <Cocoa/Cocoa.h>


extern NSString  *ToolbarOpenItem;
extern NSString  *ToolbarDeleteItem;
extern NSString  *ToolbarToggleInfoDrawer;


@class DirectoryViewControl;

@interface DirectoryViewToolbarControl : NSObject {

  IBOutlet NSWindow  *dirViewWindow;

  IBOutlet NSSegmentedControl  *navigationControls;
  IBOutlet NSSegmentedControl  *selectionControls;

  DirectoryViewControl  *dirView;

}

- (IBAction) navigationAction: (id) sender;
- (IBAction) selectionAction: (id) sender;

@end
