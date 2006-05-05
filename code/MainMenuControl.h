#import <Cocoa/Cocoa.h>

@class WindowManager;
@class AsynchronousTaskManager;

@interface MainMenuControl : NSObject {
  WindowManager  *windowManager;
  
  AsynchronousTaskManager  *scanTaskManager;
}

- (IBAction) openDirectoryView:(id)sender;
- (IBAction) duplicateDirectoryView:(id)sender;
- (IBAction) twinDirectoryView:(id)sender;
- (IBAction) saveDirectoryViewImage:(id)sender;

@end
