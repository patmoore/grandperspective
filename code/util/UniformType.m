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
        [ancestors addObject: parentType];
        [toVisit addObject: parentType];
      }
    }
  }

  return ancestors;
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

@end