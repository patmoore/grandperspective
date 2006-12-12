#import <Cocoa/Cocoa.h>

#import "StringTest.h"

/**
 * (Abstract) string test with one or more possible matches.
 */
@interface MultiMatchStringTest : NSObject<StringTest> {

  NSArray*  matches;

}

- (id) initWithMatchTargets:(NSArray*)matches;

- (NSArray*) matchTargets;

// Helper methods for storing and restoring objects from preferences. These
// are meant to be used and overridden by subclasses, and should not be 
// called directly.
- (id) initWithPropertiesFromDictionary: (NSDictionary *)dict;
- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict;

@end
