#import "UniformType.h"

#import "UniformTypeInventory.h"

@implementation UniformType

// Overrides super's designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithUniformTypeIdentifier: instead.");  
}

- (id) initWithUniformTypeIdentifier: (NSString *)utiVal {
  return [self initWithUniformTypeIdentifier: utiVal
                 inventory: [UniformTypeInventory defaultUniformTypeInventory]];
}

- (id) initWithUniformTypeIdentifier: (NSString *)utiVal 
         inventory: (UniformTypeInventory *)inventory {

  if (self = [super init]) {  
    uti = [utiVal retain];
    
    NSDictionary  *dict = 
      (NSDictionary*) UTTypeCopyDeclaration( (CFStringRef)uti );

    description = 
      [dict objectForKey: (NSString*)kUTTypeDescriptionKey];
    if (description == nil) {
      description = uti;
    }
    [description retain];
    
    NSObject  *conforms = 
      [dict objectForKey: (NSString*)kUTTypeConformsToKey];
    if ([conforms isKindOfClass: [NSArray class]]) {
      NSArray  *utiArray = (NSArray *)conforms;

      // Create the corresponding array of type objects.
      NSMutableArray  *typeArray = 
        [NSMutableArray arrayWithCapacity: [utiArray count]];
      
      NSEnumerator  *utiEnum = [utiArray objectEnumerator];
      NSString  *parentUti;
      while (parentUti = [utiEnum nextObject]) {
        UniformType  *parentType =
           [inventory uniformTypeForIdentifier: (NSString *)parentUti];
        [typeArray addObject: parentType];
      }

      parents = [NSSet setWithArray: typeArray];
    }
    else if ([conforms isKindOfClass: [NSString class]]) {
      UniformType  *parentType = 
        [inventory uniformTypeForIdentifier: (NSString *)conforms];
      parents = [NSSet setWithObject: parentType];
    }
    else {
      parents = [NSSet set];
    }
    [parents retain];
    
    children = [[NSSet set] retain];
  }
  
  return self;
  
}

- (void) dealloc {
  [uti release];
  [description release];
  [parents release];
  [children release];
  
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

- (NSSet *)childTypes {
  return children;
}

- (void) addChildType: (UniformType *)child {
  NSAssert(! [children containsObject: child], @"Child already added.");
 
  // Add child to (immutable) children set 
  NSMutableSet  *mutableSet = 
    [NSMutableSet setWithCapacity: [children count] + 1];
  [mutableSet setSet: children];
  [mutableSet addObject: child];
  
  [children release];
  children = [[NSSet setWithSet: mutableSet] retain];
}


- (BOOL) conformsToType: (UniformType *)type {
  NSMutableArray  *toVisit = [NSMutableArray arrayWithCapacity: 16];
  [toVisit addObject: self];

  // The "encountered" set is used to ensure that each (ancestor) type is
  // checked only once. This is not only more efficient, but also prevents
  // the search from entering an endless loop should the type "hierarchy"
  // unexpectedly contain cycles.
  NSMutableSet  *encountered = [NSMutableSet setWithCapacity: 16];
  [encountered addObject: self];

  while ([toVisit count] > 0) {
    // Visit next node in the list.
    UniformType  *current = [toVisit lastObject];
    [toVisit removeLastObject];
  
    if (type == current) {
      // Found it!
      return YES;
    }

    // Add parents that have not yet been encountered to list of nodes to visit. 
    NSEnumerator  *parentsEnum = [[current parentTypes] objectEnumerator];
    UniformType  *parentType;
    while (parentType = [parentsEnum nextObject]) {
      if (! [encountered containsObject: parentType]) {
        [encountered addObject: parentType];
        [toVisit addObject: parentType];
      }
    }
  }
  
  // Visited all ancestor nodes without any luck.
  return NO;
}

@end