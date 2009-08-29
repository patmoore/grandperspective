#import <Cocoa/Cocoa.h>

@class WindowManager;
@class VisibleAsynchronousTaskManager;
@class EditFilterWindowControl;
@class PreferencesPanelControl;

@interface MainMenuControl : NSObject {
  WindowManager  *windowManager;
  
  VisibleAsynchronousTaskManager  *scanTaskManager;
  VisibleAsynchronousTaskManager  *filterTaskManager;
  VisibleAsynchronousTaskManager  *writeTaskManager;
  VisibleAsynchronousTaskManager  *readTaskManager;
  
  PreferencesPanelControl  *preferencesPanelControl;
}

+ (MainMenuControl *)singletonInstance;

- (IBAction) scanDirectoryView: (id) sender;
- (IBAction) scanFilteredDirectoryView: (id) sender;
- (IBAction) rescanDirectoryView: (id) sender;
- (IBAction) filterDirectoryView: (id) sender;
- (IBAction) duplicateDirectoryView: (id) sender;
- (IBAction) twinDirectoryView: (id) sender;

- (IBAction) saveScanData: (id) sender;
- (IBAction) loadScanData: (id) sender;

- (IBAction) saveDirectoryViewImage: (id) sender;

- (IBAction) editPreferences: (id) sender;

- (IBAction) toggleToolbarShown: (id) sender;
- (IBAction) customizeToolbar: (id) sender;

- (IBAction) openWebsite: (id) sender;

@end
