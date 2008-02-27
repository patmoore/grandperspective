#import "UniformTypeRanking.h"

#import "UniformType.h"
#import "UniformTypeInventory.h"


NSString  *UniformTypeRankingChangedEvent = @"uniformTypeRankingChanged";

NSString  *UniformTypesRankingKey = @"uniformTypesRanking";

@interface UniformTypeRanking (PrivateMethods) 

- (void) uniformTypeAdded: (NSNotification *)notification;

@end


@implementation UniformTypeRanking

+ (UniformTypeRanking *)defaultUniformTypeRanking {
  static UniformTypeRanking
    *defaultUniformTypeRankingInstance = nil;

  if (defaultUniformTypeRankingInstance==nil) {
    defaultUniformTypeRankingInstance = [[UniformTypeRanking alloc] init];
  }
  
  return defaultUniformTypeRankingInstance;
}


- (id) init {
  if (self = [super init]) {
    rankedTypes = [[NSMutableArray alloc] initWithCapacity: 32];
  }
  
  return self;
}

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver: self];

  [rankedTypes release];
  
  [super dealloc];
}


- (void) loadRanking: (UniformTypeInventory *)typeInventory {
  NSAssert([rankedTypes count] == 0, @"List must be empty before load.");
  
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];  
  NSArray  *rankedUTIs = [userDefaults arrayForKey: UniformTypesRankingKey];
  
  NSEnumerator  *utiEnum = [rankedUTIs objectEnumerator];
  NSString  *uti;
  while (uti = [utiEnum nextObject]) {
    UniformType  *type = [typeInventory uniformTypeForIdentifier: uti];
    
    if (type != nil) {
      // Only add the type if a UniformType instance was created successfully.
      [rankedTypes addObject: type];
    }
  }
  
  NSLog(@"Loaded %d types from preferences (%d discarded)", 
           [rankedTypes count], [rankedUTIs count] - [rankedTypes count]);
}

- (void) storeRanking {
  NSMutableArray  *rankedUTIs =
    [[NSMutableArray alloc] initWithCapacity: [rankedTypes count]];
    
  NSMutableSet  *encountered = 
    [NSMutableSet setWithCapacity: [rankedUTIs count]];
    
  NSEnumerator  *typeEnum = [rankedTypes objectEnumerator];
  UniformType  *type;
  while (type = [typeEnum nextObject]) {
    NSString  *uti = [type uniformTypeIdentifier];
    
    if (! [encountered containsObject: uti]) {
      // Should the ranked list contain duplicate UTIs, only add the first.
      [encountered addObject: uti];
     
      [rankedUTIs addObject: uti];
    }
  }
  
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  
  [userDefaults setObject: rankedUTIs forKey: UniformTypesRankingKey];
  
  NSLog(@"Stored %d types to preferences (%d discarded)", 
           [rankedUTIs count], [rankedTypes count] - [rankedUTIs count]);
}


- (void) observeUniformTypeInventory: (UniformTypeInventory *)typeInventory {
  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];

  // Observe the inventory to for newly added types so that these can be added
  // to (the end of) the ranked list. 
  [nc addObserver: self selector: @selector(uniformTypeAdded:)
        name: UniformTypeAddedEvent object: typeInventory];
        
  // Also add any types in the inventory that are not yet in the ranking
  NSMutableSet  *typesInRanking = 
    [NSMutableSet setWithCapacity: ([rankedTypes count] + 16)];

  [typesInRanking addObjectsFromArray: rankedTypes];
  NSEnumerator  *typesEnum = [typeInventory uniformTypeEnumerator];
  UniformType  *type;
  while (type = [typesEnum nextObject]) {
    if (! [typesInRanking containsObject: type]) {
      [rankedTypes addObject: type];
      [typesInRanking addObject: type];  
    }
  }
}


- (NSArray *) rankedUniformTypes {
  // Return an immutable copy of the array.
  return [NSArray arrayWithArray: rankedTypes];  
}

- (void) updateRankedUniformTypes: (NSArray *)ranking {
  // Updates the ranking while keeping new types that may have appeared in the
  // meantime.
  [rankedTypes replaceObjectsInRange: NSMakeRange(0, [ranking count])
                 withObjectsFromArray: ranking];
  
  // Notify any observers.
  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];  
  [nc postNotificationName: UniformTypeRankingChangedEvent object: self];
}


- (BOOL) isUniformTypeDominated: (UniformType *)type {
  int  i = 0;
  int  i_max = [rankedTypes count];
  
  NSSet  *ancestors = [type ancestorTypes];
  
  while (i < i_max) {
    UniformType  *higherType = [rankedTypes objectAtIndex: i];
    
    if (higherType == type) {
      // Found the type in the list, without encountering any type that 
      // dominates it.
      return NO;
    }

    if ([ancestors containsObject: higherType]) {
      // Found a type that dominates this one.
      return YES;
    }
    
    i++;
  }
}

- (NSArray *) undominatedRankedUniformTypes {
  NSMutableArray  *undominatedTypes = 
    [NSMutableArray arrayWithCapacity: [rankedTypes count]];
    
  int  i = 0;
  int  i_max = [rankedTypes count];

  while (i < i_max) {
    UniformType  *type = [rankedTypes objectAtIndex: i];
    
    if (! [self isUniformTypeDominated: type]) {
      [undominatedTypes addObject: type];
    }
    
    i++;
  }
  
  return undominatedTypes;
}

@end // @implementation UniformTypeRanking


@implementation UniformTypeRanking (PrivateMethods) 

- (void) uniformTypeAdded: (NSNotification *)notification {
  UniformType  *type = [[notification userInfo] objectForKey: UniformTypeKey];

  [rankedTypes addObject: type];

  NSLog(@"uniformTypeAdded: %@", type);
}

@end // @implementation UniformTypeRanking (PrivateMethods) 
