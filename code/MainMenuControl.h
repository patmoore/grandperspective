#import <Cocoa/Cocoa.h>

@class WindowManager;

@interface MainMenuControl : NSObject {
  WindowManager  *windowManager;
}

- (IBAction) openDirectoryView:(id)sender;
- (IBAction) duplicateDirectoryView:(id)sender;
- (IBAction) twinDirectoryView:(id)sender;
- (IBAction) saveDirectoryViewImage:(id)sender;

@end
