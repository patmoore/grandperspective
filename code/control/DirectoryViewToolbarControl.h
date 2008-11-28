#import <Cocoa/Cocoa.h>


extern NSString  *ToolbarNavigateUp;
extern NSString  *ToolbarNavigateDown; 
extern NSString  *ToolbarOpenItem;
extern NSString  *ToolbarDeleteItem;
extern NSString  *ToolbarToggleInfoDrawer;


@class DirectoryViewControl;

@interface DirectoryViewToolbarControl : NSObject {

  IBOutlet NSWindow  *dirViewWindow;
  IBOutlet NSView  *navigationView;
  IBOutlet NSSegmentedControl  *navigationControls;

  DirectoryViewControl  *dirView;

}

- (IBAction) navigationAction: (id) sender;

@end
