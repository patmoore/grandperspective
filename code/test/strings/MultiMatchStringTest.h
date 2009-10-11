#import <Cocoa/Cocoa.h>

#import "StringTest.h"

/**
 * (Abstract) string test with one or more possible matches.
 */
@interface MultiMatchStringTest : StringTest {

  NSArray  *matches;
  BOOL  caseSensitive;

}

- (id) initWithMatchTargets:(NSArray *)matches;
- (id) initWithMatchTargets:(NSArray *)matches caseSensitive:(BOOL) caseFlag;

- (NSArray *)matchTargets;
- (BOOL) isCaseSensitive;

@end
