#import "UniformTypeHashingScheme.h"

#import "StatefulFileItemHashing.h"
#import "PlainFileItem.h"
#import "UniformType.h"
#import "UniformTypeRanking.h"


@interface UniformTypeHashingScheme (PrivateMethods)

- (void) typeRankingChanged: (NSNotification *)notification;

@end


@interface HashingByUniformType : StatefulFileItemHashing {

  // Cache mapping UTIs (NSString) to integer values (NSNumber)
  NSMutableDictionary  *hashForUTICache;
  
  NSArray  *orderedTypes;
}

@end


@implementation UniformTypeHashingScheme

- (id) init {
  return [self initWithUniformTypeRanking: 
                 [UniformTypeRanking defaultUniformTypeRanking]];

}

- (id) initWithUniformTypeRanking: (UniformTypeRanking *)typeRankingVal {
  if (self = [super init]) {
    typeRanking = [typeRankingVal retain];
    
    NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver: self selector: @selector(typeRankingChanged:)
          name: UniformTypeRankingChangedEvent object: typeRanking];
  }
  
  return self;
}

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  
  [typeRanking release];
  
  [super dealloc];
}


- (UniformTypeRanking *)uniformTypeRanking {
  return typeRanking;
}


//----------------------------------------------------------------------------
// Implementation of FileItemHashingScheme protocol

- (NSObject <FileItemHashing> *) fileItemHashing {
  return [[[HashingByUniformType alloc] initWithFileItemHashingScheme: self]
              autorelease];
}

@end // @implementation UniformTypeHashingScheme


@implementation UniformTypeHashingScheme (PrivateMethods)

- (void) typeRankingChanged: (NSNotification *)notification {
  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];
  
  [nc postNotificationName: HashingSchemeChangedEvent object: self];
}

@end // @implementation UniformTypeHashingScheme (PrivateMethods)


@implementation HashingByUniformType

- (id) initWithFileItemHashingScheme: 
                                (NSObject <FileItemHashingScheme> *)schemeVal {

  if (self = [super initWithFileItemHashingScheme: schemeVal]) {
    hashForUTICache = 
      [[NSMutableDictionary dictionaryWithCapacity: 16] retain];
    
    UniformTypeRanking  *typeRanking =
      [((UniformTypeHashingScheme *)schemeVal) uniformTypeRanking];
    
    orderedTypes = [[typeRanking undominatedRankedUniformTypes] retain];
  }
  
  return self;
}

- (void) dealloc {
  [hashForUTICache release];

  [orderedTypes release];
  
  [super dealloc];
}


//----------------------------------------------------------------------------
// Implementation of FileItemHashing protocol

- (int) hashForFileItem: (PlainFileItem *)item depth: (int)depth {
  UniformType  *type = [item uniformType];
  
  if (type == nil) {
    // Unknown type
    return INT_MAX;
  }
  
  NSString  *uti = [type uniformTypeIdentifier];
  NSNumber  *hash = [hashForUTICache objectForKey: uti];
  if (hash != nil) {
    return [hash intValue];
  }
    
  NSSet  *ancestorTypes = [type ancestorTypes];
  int  utiIndex = 0;
  
  while (utiIndex < [orderedTypes count]) {
    UniformType  *orderedType = [orderedTypes objectAtIndex: utiIndex];
  
    if (type == orderedType || [ancestorTypes containsObject: orderedType]) {
      // Found the first type in the list that the file item conforms to.
      
      // Add it to the cache for next time.
      [hashForUTICache setObject: [NSNumber numberWithInt: utiIndex]
                         forKey: uti];
      return utiIndex;
    }
    
    utiIndex++;
  }
  
  NSAssert(NO, @"No conforming type found.");
}

- (BOOL) canProvideLegend {
  return YES;
}

- (NSString *) descriptionForHash: (int)hash {
  if (hash < 0 || hash >= [orderedTypes count]) {
    return nil;
  }
  
  UniformType  *type = [orderedTypes objectAtIndex: hash];
   
  return [type description];
}

@end
