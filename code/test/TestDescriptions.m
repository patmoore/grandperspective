#import "TestDescriptions.h"


NSString *descriptionForMatches(NSArray *matches) {

  NSEnumerator  *matchEnum = [matches objectEnumerator];

  // Can assume there is always one.
  NSString  *matchesDescr = [matchEnum nextObject];

  NSString  *match = [matchEnum nextObject];
  if (match) {
    // At least two match targets.
    NSString  *pairTemplate = 
      NSLocalizedStringFromTable( 
        @"%@ or %@" , @"Tests", 
        @"Pair of match targets with 1: a target match, and 2: another target match" );
      
    matchesDescr = 
      [NSString stringWithFormat: pairTemplate, match, matchesDescr];

    NSString  *moreTemplate = 
      NSLocalizedStringFromTable( 
        @"%@, %@" , @"Tests", 
        @"Three or more match targets with 1: a target match, and 2: two or more other target matches" );

    while (match = [matchEnum nextObject]) {
      // Three or more
      matchesDescr = 
        [NSString stringWithFormat: moreTemplate, match, matchesDescr];
    }
  }
  
  return matchesDescr;
}