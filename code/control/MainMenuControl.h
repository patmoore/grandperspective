#import <Cocoa/Cocoa.h>

@class WindowManager;
@class VisibleAsynchronousTaskManager;
@class EditFilterWindowControl;
@class PreferencesPanelControl;

@interface MainMenuControl : NSObject {
  WindowManager  *windowManager;
  
  VisibleAsynchronousTaskManager  *scanTaskManager;
  VisibleAsynchronousTaskManager  *rescanTaskManager;
  VisibleAsynchronousTaskManager  *filterTaskManager;
  
  EditFilterWindowControl  *editFilterWindowControl;
  PreferencesPanelControl  *preferencesPanelControl;
}

- (IBAction) openDirectoryView:(id)sender;
- (IBAction) rescanDirectoryView:(id)sender;
- (IBAction) filterDirectoryView:(id)sender;
- (IBAction) duplicateDirectoryView:(id)sender;
- (IBAction) twinDirectoryView:(id)sender;

- (IBAction) saveDirectoryViewImage:(id)sender;

- (IBAction) editPreferences:(id)sender;

@end
