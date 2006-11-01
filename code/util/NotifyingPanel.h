#import <Cocoa/Cocoa.h>


/**
 * Panel which notifies its delegate when its first responder changed.
 */
@interface NotifyingPanel : NSPanel {

}

// Method which can be implemented by delegate
- (void) windowFirstResponderChanged: (NSNotification*) notification;

@end
