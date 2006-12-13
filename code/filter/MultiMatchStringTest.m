#import "MultiMatchStringTest.h"


@interface MultiMatchStringTest (PrivateMethods) 

// Not implemented. Needs to be provided by subclass.
- (BOOL) testString:(NSString*)string matches:(NSString*)match;

// Not implemented. Needs to be provided by subclass.
//
// It should return a string with two "%@" arguments. The first for the
// subject of the test and the second for the description of the match
// targets.
- (NSString*) descriptionFormat;

@end


@implementation MultiMatchStringTest

- (id) initWithMatchTargets: (NSArray *)matchesVal {
  return [self initWithMatchTargets: matchesVal caseSensitive: YES];
}
  
- (id) initWithMatchTargets: (NSArray *)matchesVal
         caseSensitive: (BOOL)caseFlag {
  if (self = [super init]) {
    NSAssert([matchesVal count] >= 1, 
             @"There must at least be one possible match.");

    // Make the array immutable
    matches = [[NSArray alloc] initWithArray:matchesVal];
    caseSensitive = caseFlag;
  }
  
  return self;
}

- (void) dealloc {
  [matches release];

  [super dealloc];
}


// Note: Special case. Does not call own designated initialiser. It should
// be overridden and only called by initialisers with the same signature.
- (id) initWithPropertiesFromDictionary: (NSDictionary *)dict {
  if (self = [super init]) {
    NSArray  *tmpMatches = [dict objectForKey: @"matches"];
    
    // Make the array immutable
    matches = [[NSArray alloc] initWithArray: tmpMatches];
    
    caseSensitive = [[dict objectForKey: @"caseSensitive"] boolValue];
  }
  
  return self;
}

- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict {
  [dict setObject: matches forKey: @"matches"];
  
  [dict setObject: [NSNumber numberWithBool: caseSensitive] 
          forKey: @"caseSensitive"];
}


- (NSDictionary *) dictionaryForObject {
  NSMutableDictionary  *dict = [NSMutableDictionary dictionaryWithCapacity: 8];
  
  [self addPropertiesToDictionary: dict];
  
  return dict;
}


- (NSArray*) matchTargets {
  return matches;
}

- (BOOL) isCaseSensitive {
  return caseSensitive;
}


- (BOOL) testString: (NSString *)string {
  int  i = [matches count];
  while (--i >= 0) {
    if ([self testString: string matches: [matches objectAtIndex: i]]) {
      return YES;
    }
  }
  
  return NO;
}


- (NSString*) descriptionWithSubject: (NSString*)subject {
  NSEnumerator  *matchEnum = [matches objectEnumerator];

  // Can assume there is always one.
  NSString  *matchesDescr = [matchEnum nextObject];

  NSString  *match = [matchEnum nextObject];
  if (match) {
    // At least two match targets.
    NSString  *pairTemplate = 
      NSLocalizedStringFromTable( 
        @"%@ or %@" , @"tests", 
        @"Pair of match targets with 1: a target match, and 2: another target match" );
      
    matchesDescr = 
      [NSString stringWithFormat: pairTemplate, match, matchesDescr];

    NSString  *moreTemplate = 
      NSLocalizedStringFromTable( 
        @"%@, %@" , @"tests", 
        @"Three or more match targets with 1: a target match, and 2: two or more other target matches" );

    while (match = [matchEnum nextObject]) {
      // Three or more
      matchesDescr = 
        [NSString stringWithFormat: moreTemplate, match, matchesDescr];
    }
  }

  NSString  *format = [self descriptionFormat];
  
  return [NSString stringWithFormat: format, subject, matchesDescr];
}

@end // @implementation MultiMatchStringTest

