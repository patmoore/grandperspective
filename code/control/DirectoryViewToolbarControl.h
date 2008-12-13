#import <Cocoa/Cocoa.h>


@class DirectoryViewControl;

@interface DirectoryViewToolbarControl : NSObject {

  IBOutlet NSWindow  *dirViewWindow;

  IBOutlet NSSegmentedControl  *zoomControls;
  IBOutlet NSSegmentedControl  *focusControls;
  
  int  zoomInSegment;
  int  zoomOutSegment;
  int  focusUpSegment;
  int  focusDownSegment;

  DirectoryViewControl  *dirView;

}

- (IBAction) zoomAction: (id) sender;
- (IBAction) focusAction: (id) sender;

@end
