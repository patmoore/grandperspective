#import <Cocoa/Cocoa.h>


/* Although its name and API suggest a more general window management
 * functionality, all that this class does is managing the titles of windows
 * so that each is unique. Also, it takes care of the placement of new windows.
 */
@interface WindowManager : NSObject {
  // The keys are window (base) titles, the values the number of windows
  // created with that title.
  NSMutableDictionary  *titleLookup;
  
  // The position of the next window that is added
  NSPoint  nextWindowPosition;
}

- (void) addWindow: (NSWindow *)window usingTitle: (NSString *)title;

@end
