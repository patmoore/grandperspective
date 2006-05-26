#import <Cocoa/Cocoa.h>

#import "StringTest.h"

/**
 * (Abstract) string test with one or more possible matches.
 */
@interface MultiMatchStringTest : NSObject<StringTest> {

  NSArray*  matches;

}

- (id) initWithMatches:(NSArray*)matches;

@end
