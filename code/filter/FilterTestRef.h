#import <Cocoa/Cocoa.h>

/* A test that is part of a Filter.
 */
@interface FilterTestRef : NSObject {
  NSString  *name;

  // Is the test inverted?
  BOOL  inverted;
  
  // Can the inverted state be changed?
  BOOL  canToggleInverted;
}

+ (id) filterTestWithName:(NSString *)name;

- (id) initWithName:(NSString *)name;
- (id) initWithName:(NSString *)name inverted:(BOOL) inverted;

- (NSString *) name;
- (BOOL) isInverted;

- (void) setCanToggleInverted:(BOOL) flag;
- (BOOL) canToggleInverted;

- (void) toggleInverted;

@end
