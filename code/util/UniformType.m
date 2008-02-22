#import "UniformType.h"

@implementation UniformType

// Overrides super's designated initialiser.
- (id) init {
  NSAssert(NO, 
           @"Use initWithUniformTypeIdentifier:description:parents instead.");  
}


- (id) initWithUniformTypeIdentifier: (NSString *)utiVal
         description: (NSString *)descriptionVal
         parents: (NSArray *)parentTypes {

  if (self = [super init]) {  
    uti = [utiVal retain];
    description = [descriptionVal retain];
    
    parents = [[NSSet setWithArray: parentTypes] retain];
  }
  
  return self;
  
}

- (void) dealloc {
  [uti release];
  [description release];
  [parents release];
  
  [super dealloc];
}


- (NSString *)uniformTypeIdentifier {
  return uti;
}

- (NSString *)description {
  return description;
}

- (NSSet *)parentTypes {
  return parents;
}


- (NSSet *)ancestorTypes {
  NSMutableSet  *ancestors = [NSMutableSet setWithCapacity: 16];

  NSMutableArray  *toVisit = [NSMutableArray arrayWithCapacity: 8];
  [toVisit addObject: self];
  
  while ([toVisit count] > 0) {
    // Visit next node in the list.
    UniformType  *current = [toVisit lastObject];
    [toVisit removeLastObject];
  
    // Add parents that have not yet been encountered to list of nodes to visit. 
    NSEnumerator  *parentsEnum = [[current parentTypes] objectEnumerator];
    UniformType  *parentType;
    while (parentType = [parentsEnum nextObject]) {
      if (! [ancestors containsObject: parentType]) {
        // Only visit ancestor types that have not yet been encountered. This
        // ensures that the search time is lineair in the number of ancestors
        // (despite there possibly being multiple paths to certain ancestors).
        [ancestors addObject: parentType];
        [toVisit addObject: parentType];
      }
    }
  }

  return ancestors;
}

@end