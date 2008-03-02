#import "UniformTypeMappingScheme.h"

#import "StatefulFileItemMapping.h"
#import "PlainFileItem.h"
#import "UniformType.h"
#import "UniformTypeRanking.h"


@interface UniformTypeMappingScheme (PrivateMethods)

- (void) typeRankingChanged: (NSNotification *)notification;

@end


@interface MappingByUniformType : StatefulFileItemMapping {

  // Cache mapping UTIs (NSString) to integer values (NSNumber)
  NSMutableDictionary  *hashForUTICache;
  
  NSArray  *orderedTypes;
}

@end


@implementation UniformTypeMappingScheme

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
// Implementation of FileItemMappingScheme protocol

- (NSObject <FileItemMapping> *) fileItemMapping {
  return [[[MappingByUniformType alloc] initWithFileItemMappingScheme: self]
              autorelease];
}

@end // @implementation UniformTypeMappingScheme


@implementation UniformTypeMappingScheme (PrivateMethods)

- (void) typeRankingChanged: (NSNotification *)notification {
  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];
  
  [nc postNotificationName: MappingSchemeChangedEvent object: self];
}

@end // @implementation UniformTypeMappingScheme (PrivateMethods)


@implementation MappingByUniformType

- (id) initWithFileItemMappingScheme: 
                                (NSObject <FileItemMappingScheme> *)schemeVal {

  if (self = [super initWithFileItemMappingScheme: schemeVal]) {
    hashForUTICache = 
      [[NSMutableDictionary dictionaryWithCapacity: 16] retain];
    
    UniformTypeRanking  *typeRanking =
      [((UniformTypeMappingScheme *)schemeVal) uniformTypeRanking];
    
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
// Implementation of FileItemMapping protocol

- (int) hashForFileItem: (PlainFileItem *)item atDepth: (int)depth {
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

//----------------------------------------------------------------------------
// Implementation of informal LegendProvidingFileItemMapping protocol

- (NSString *) descriptionForHash: (int)hash {
  if (hash < 0 || hash >= [orderedTypes count]) {
    return nil;
  }
  
  UniformType  *type = [orderedTypes objectAtIndex: hash];
  
  NSString  *descr = [type description];
   
  return (descr != nil) ? descr : [type uniformTypeIdentifier];
}

- (NSString *) descriptionForRemainingHashes {
  return NSLocalizedString
           (@"other file types",
            @"Misc. description for File type mapping scheme.");
}

@end
