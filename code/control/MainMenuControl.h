#import <Cocoa/Cocoa.h>

@class WindowManager;
@class VisibleAsynchronousTaskManager;
@class EditFilterWindowControl;

@interface MainMenuControl : NSObject {
  WindowManager  *windowManager;
  
  VisibleAsynchronousTaskManager  *scanTaskManager;
  
  EditFilterWindowControl  *editFilterWindowControl;
}

- (IBAction) openDirectoryView:(id)sender;
- (IBAction) rescanDirectoryView:(id)sender;
- (IBAction) filterDirectoryView:(id)sender;
- (IBAction) duplicateDirectoryView:(id)sender;
- (IBAction) twinDirectoryView:(id)sender;
- (IBAction) saveDirectoryViewImage:(id)sender;

@end
