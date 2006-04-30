#import <Cocoa/Cocoa.h>


/* Although its name and API suggest a more general window management
 * functionality, all that this class does is managing the titles of windows
 * so that each is unique.
 */
@interface WindowManager : NSObject {
  // The keys are window (base) titles, the values the number of windows
  // created with that title.
  NSMutableDictionary  *titleLookup;
}

- (void) addWindow:(NSWindow*)window usingTitle:(NSString*)title;

@end
