#import "MultiMatchStringTest.h"


@interface MultiMatchStringTest (PrivateMethods) 

// Not implemented. Needs to be provided by subclass.
- (BOOL) testString:(NSString*)string matches:(NSString*)match;

// Not implemented. Needs to be provided by subclass.
- (NSString*) descriptionOfTest;

@end


@implementation MultiMatchStringTest

- (id) initWithMatchTargets:(NSArray*)matchesVal {
  if (self = [super init]) {
    NSAssert([matchesVal count] >= 1, 
             @"There must at least be one possible match.");

    // Make the array immutable
    matches = [[NSArray alloc] initWithArray:matchesVal];
  }
  
  return self;
}

- (void) dealloc {
  [matches release];

  [super dealloc];
}


- (NSArray*) matchTargets {
  return matches;
}


- (BOOL) testString:(NSString*)string {
  NSEnumerator*  matchEnum = [matches objectEnumerator];
  NSString*  match;
  while (match = [matchEnum nextObject]) {
    if ([self testString:string matches:match]) {
      return YES;
    }
  }
  
  return NO;
}

- (NSString*) descriptionWithSubject:(NSString*)subject {
  NSMutableString*  descr = [NSMutableString stringWithCapacity:128];
  
  [descr setString:subject];
  [descr appendString:@" "];
  [descr appendString:[self descriptionOfTest]];
  [descr appendString:@" "];
  
  NSEnumerator*  matchEnum = [matches objectEnumerator];

  // Can assume there is always one.
  [descr appendString:[matchEnum nextObject]];

  NSString*  match = [matchEnum nextObject];

  if (match) {
    NSString*  prevMatch = match;
  
    while (match = [matchEnum nextObject]) {
      [descr appendString:@", "];
      [descr appendString:prevMatch];
      prevMatch = match;
    }
    [descr appendString:@" or "];
    [descr appendString:prevMatch];
  }

  return descr;
}

@end
